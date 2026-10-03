# Enterprise AKS Terraform

Terraform configuration for an enterprise Azure Kubernetes Service cluster. The root module owns the resource group and calls separate `modules/network` and `modules/aks` modules. The module implementations use Azure Verified Modules (AVM) as the reference pattern.

The infrastructure also provisions an Azure Container Registry using AVM (`Basic` SKU for development cost control, admin account disabled) and grants the AKS kubelet identity the `AcrPull` role. It creates a dedicated private runner subnet and provisions a Linux runner VM from a separate AVM module. ACR is currently public-network accessible; use Premium SKU, a private endpoint, and private DNS before requiring private registry access. The sample application continues to use upstream GHCR/MCR images until the app workflow is extended to build and push images to this ACR.

## Naming

Names follow `rg-manish-eus2-dev-xxxxx-01`. The five or six character `random_identifier` is an explicit input so names remain deterministic across plans. Resource prefixes include `vnet`, `aks`, `uai`, `kv`, and `acr`.

## Prerequisites

- Terraform >= 1.10 and Azure CLI.
- A state backend configured for the deployment pipeline or supplied with `-backend-config`.
- An Azure federated identity credential for GitHub Actions with `id-token: write`.
- The pipeline identity needs at least Contributor on the target scope and User Access Administrator if Terraform creates role assignments.
- A Microsoft Entra admin group object ID.

## Local use

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace every placeholder.
2. Authenticate with Azure CLI or service principal OIDC.
3. Run `terraform init`, `terraform fmt -check -recursive`, `terraform validate`, and `terraform plan`.
4. Apply only after reviewing the plan.

The workflow runs fmt, init, validate, and plan for pull requests. A push to `main` applies the reviewed plan behind the `production` GitHub environment protection. Manual runs support `plan`, `apply`, and `destroy`; `apply` and `destroy` require approval from the `production` environment.

To destroy the managed resources, open the **terraform** GitHub Actions workflow, select **Run workflow**, choose `destroy`, and approve the `production` environment. The workflow creates a `terraform plan -destroy` plan and applies that reviewed destroy plan. Do not use `terraform destroy` against a normal plan file.

CI uses the optional `TF_RANDOM_IDENTIFIER` repository variable when it is set. Otherwise, it derives a stable five-character identifier from the repository name, so the required Terraform variable is never passed as an empty string.

## Team Namespace Access

The cluster uses Microsoft Entra integration and Azure RBAC for Kubernetes authorization. Add one entry per Entra group and namespace to `namespace_access`; Terraform assigns the built-in AKS RBAC Reader, Writer, or Admin role at `<cluster-resource-id>/namespaces/<namespace>`. Use the group's object ID, not its display name. Keep `admin_group_object_ids` limited to platform administrators; do not grant application teams cluster-admin access.

Example:

```hcl
namespace_access = {
	payments_writer = {
		namespace             = "payments"
		entra_group_object_id = "<payments-team-group-object-id>"
		role_definition_name  = "Azure Kubernetes Service RBAC Writer"
	}
	payments_reader = {
		namespace             = "payments"
		entra_group_object_id = "<payments-readers-group-object-id>"
		role_definition_name  = "Azure Kubernetes Service RBAC Reader"
	}
}
```

Namespace creation is a Kubernetes API operation and is not included in the current Terraform workflow. This cluster has a private API server, so create namespaces through a runner or platform pipeline with network access to the cluster, then apply the namespace-scoped Azure role assignments. Azure RBAC assignments provide API authorization isolation; they do not isolate pod-to-pod network traffic. Add default-deny Kubernetes NetworkPolicies and namespace-level resource quotas/limits for workload isolation and fair resource use.

## Application Deployment

The upstream AKS Store Demo repository is copied under `app/`. Its `aks-store-all-in-one.yaml` deploys the sample microservices using the upstream public container images; this pipeline does not build images. Application delivery is separate from infrastructure provisioning: `.github/workflows/deploy-app.yml` runs only for pushes to `main` that change files under `app/**`.

The AKS API server is private, so the Terraform-managed runner VM uses the `snet-runner-*` subnet in the same VNet, has no public IP, and receives Azure CLI, `kubectl`, and `kubelogin` through cloud-init. Set `runner_admin_ssh_public_key` to a public key you control. The workflow uses the GitHub OIDC service principal and applies the sample manifest to the `pets` namespace.

The VM is not automatically registered as a GitHub runner. After Terraform creates it, connect through your corporate VPN, Azure Bastion, or another approved private management path. In the GitHub repository, open **Settings > Actions > Runners > New self-hosted runner**, follow the Linux registration steps, add the `aks-private` label, and install/start the runner as a service. Do not pass the short-lived runner registration token through Terraform, cloud-init, or a saved plan.

The runner subnet has no public IP or implicit egress appliance configured. Provide an approved outbound route through your existing firewall/NAT to GitHub Actions endpoints, Azure control-plane endpoints, and Ubuntu package repositories. Ensure the subnet can resolve the AKS private DNS name and reach the private API endpoint. Without this egress and private routing, cloud-init package installation and app deployment will not work. The default VM size is `Standard_D2ds_v6` and the zone defaults to `null`; override either through Terraform variables if subscription quota or regional support requires it.

Configure these GitHub repository variables:

- `AKS_RESOURCE_GROUP`: for example `rg-manish-eus2-dev-1dede-01`
- `AKS_CLUSTER_NAME`: for example `aks-manish-eus2-dev-1dede-01`
- `AKS_NAMESPACE`: `pets` (optional; the workflow defaults to `pets`)
- `RUNNER_ADMIN_SSH_PUBLIC_KEY`: the SSH public key used by Terraform to create the private VM administrator account

Add them under **GitHub repository > Settings > Secrets and variables > Actions > Variables > New repository variable**. For `RUNNER_ADMIN_SSH_PUBLIC_KEY`, paste the complete single-line OpenSSH public key from `terraform.tfvars.example` (starting with `ssh-rsa`). This is a public key, not the private key. The Terraform workflow checks this Actions variable directly; it does not read the local `.tfvars` file.

The `production` GitHub environment must contain the existing `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` secrets and should have required reviewers configured. The OIDC service principal needs the Azure `Azure Kubernetes Service Cluster User Role` at cluster scope and `Azure Kubernetes Service RBAC Writer` scoped to the `pets` namespace. Use the **Object ID** of the service principal under **Microsoft Entra ID > Enterprise applications**. Do not use the app registration's object ID or the application's client ID; Azure rejects role assignments made to an `Application` principal. You can retrieve the service-principal object ID from its client ID with `az ad sp show --id <application-client-id> --query id -o tsv`. Set that service-principal object ID in Terraform and apply the grants:

```hcl
app_deployer_service_principal_object_id = "<github-oidc-service-principal-object-id>"

namespace_access = {
	app_deployer = {
		namespace                   = "pets"
		service_principal_object_id = "<github-oidc-service-principal-object-id>"
		role_definition_name        = "Azure Kubernetes Service RBAC Writer"
	}
	app_team_readers = {
		namespace             = "pets"
		entra_group_object_id = "<application-team-entra-group-object-id>"
		role_definition_name  = "Azure Kubernetes Service RBAC Reader"
	}
}
```

Apply the cluster infrastructure and cluster-user grant first. Then, using a platform-admin identity that can reach the private cluster, create the namespace with `kubectl create namespace pets`. Add the namespace-scoped role assignments and apply Terraform again. The app deployment identity is intentionally not granted cluster-wide write access. The sample manifest exposes the store front and admin services through public `LoadBalancer` services; review and replace those with approved ingress/private exposure before production use. The sample is a demonstration workload, not a production-ready application deployment.

For GitHub Actions-driven Terraform, set repository variable `AKS_DEPLOYER_OBJECT_ID` to the OIDC service principal's **Enterprise applications Object ID** and `TF_NAMESPACE_ACCESS_JSON` to a JSON object matching the `namespace_access` Terraform variable. The cluster-user assignment is skipped unless `AKS_DEPLOYER_OBJECT_ID` is set. For example:

```json
{"app_deployer":{"namespace":"pets","service_principal_object_id":"<oidc-service-principal-object-id>","role_definition_name":"Azure Kubernetes Service RBAC Writer"},"app_team_readers":{"namespace":"pets","entra_group_object_id":"<entra-group-object-id>","role_definition_name":"Azure Kubernetes Service RBAC Reader"}}
```

## Enterprise decisions to confirm

Confirm the remote state storage and locking design, approved IP ranges and private DNS topology, Azure Policy assignments, ingress and egress controls, backup and disaster recovery requirements, node pool/SKU capacity, maintenance windows, diagnostic retention, and the future Log Analytics integration.
