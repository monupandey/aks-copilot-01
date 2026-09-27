# Enterprise AKS Terraform

Terraform configuration for an enterprise Azure Kubernetes Service cluster. The root module owns the resource group and calls separate `modules/network` and `modules/aks` modules. The module implementations use Azure Verified Modules (AVM) as the reference pattern.

## Naming

Names follow `rg-manish-cin-dev-xxxxx-01`. The five or six character `random_identifier` is an explicit input so names remain deterministic across plans. Resource prefixes include `vnet`, `aks`, `uai`, `kv`, and `acr`.

## Prerequisites

- Terraform >= 1.9 and Azure CLI.
- A state backend configured for the deployment pipeline or supplied with `-backend-config`.
- An Azure federated identity credential for GitHub Actions with `id-token: write`.
- The pipeline identity needs at least Contributor on the target scope and User Access Administrator if Terraform creates role assignments.
- A Microsoft Entra admin group object ID.

## Local use

1. Copy `terraform.tfvars.example` to `terraform.tfvars` and replace every placeholder.
2. Authenticate with Azure CLI or service principal OIDC.
3. Run `terraform init`, `terraform fmt -check -recursive`, `terraform validate`, and `terraform plan`.
4. Apply only after reviewing the plan.

If the resource group was created by an earlier failed deployment and is not in the current state, import it once before planning:

```bash
terraform import azurerm_resource_group.this \
	/subscriptions/<subscription-id>/resourceGroups/rg-manish-cin-dev-<random-identifier>-01
```

The workflow runs fmt, init, validate, and plan for pull requests. A push to `main` applies the reviewed plan behind the `production` GitHub environment protection. Manual runs support `plan`, `apply`, and `destroy`; `apply` and `destroy` require approval from the `production` environment.

To destroy the managed resources, open the **terraform** GitHub Actions workflow, select **Run workflow**, choose `destroy`, and approve the `production` environment. The workflow creates a `terraform plan -destroy` plan and applies that reviewed destroy plan. Do not use `terraform destroy` against a normal plan file.

CI uses the optional `TF_RANDOM_IDENTIFIER` repository variable when it is set. Otherwise, it derives a stable five-character identifier from the repository name, so the required Terraform variable is never passed as an empty string. Before planning, CI imports the deterministic resource group, VNet, and subnets if Azure already has them but Terraform state does not.

## Enterprise decisions to confirm

Confirm the remote state storage and locking design, approved IP ranges and private DNS topology, Azure Policy assignments, ingress and egress controls, backup and disaster recovery requirements, node pool/SKU capacity, maintenance windows, diagnostic retention, and the future Log Analytics integration.
