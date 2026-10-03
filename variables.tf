variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

variable "tenant_id" {
  type        = string
  description = "Microsoft Entra tenant ID."
}

variable "location" {
  type        = string
  description = "Azure region."
  default     = "eastus2"
}

variable "environment" {
  type        = string
  description = "Short environment name."
  default     = "dev"
}

variable "workload" {
  type        = string
  description = "Workload or owner identifier used in names."
  default     = "manish"
}

variable "region_code" {
  type        = string
  description = "Short region code used in names."
  default     = "eus2"
}

variable "random_identifier" {
  type        = string
  description = "Deterministic 5-6 character identifier used in every resource name."
  validation {
    condition     = can(regex("^[a-z0-9]{5,6}$", var.random_identifier))
    error_message = "random_identifier must contain 5-6 lowercase letters or digits."
  }
}

variable "instance" {
  type        = string
  description = "Two-digit instance suffix."
  default     = "01"
}

variable "vnet_address_space" {
  type    = list(string)
  default = ["10.40.0.0/16"]
}

variable "aks_subnet_address_prefixes" {
  type    = list(string)
  default = ["10.40.0.0/20"]
}

variable "node_subnet_address_prefixes" {
  type    = list(string)
  default = ["10.40.16.0/20"]
}

variable "runner_subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the private self-hosted runner subnet."
  default     = ["10.40.32.0/24"]
}

variable "service_cidr" {
  type    = string
  default = "10.41.0.0/16"
}

variable "dns_service_ip" {
  type    = string
  default = "10.41.0.10"
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Microsoft Entra group object IDs granted AKS admin access."
  default     = []
}

variable "namespace_access" {
  description = "Namespace-scoped Azure RBAC grants for Microsoft Entra groups or service principals. Namespaces must exist in the AKS cluster."
  type = map(object({
    namespace                   = string
    entra_group_object_id       = optional(string)
    service_principal_object_id = optional(string)
    role_definition_name        = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for grant in values(var.namespace_access) :
      (grant.entra_group_object_id != null) != (grant.service_principal_object_id != null)
    ])
    error_message = "Set exactly one of entra_group_object_id or service_principal_object_id for each namespace grant."
  }

  validation {
    condition = alltrue([
      for grant in values(var.namespace_access) : contains([
        "Azure Kubernetes Service RBAC Reader",
        "Azure Kubernetes Service RBAC Writer",
        "Azure Kubernetes Service RBAC Admin",
      ], grant.role_definition_name)
    ])
    error_message = "Namespace role_definition_name must be an AKS RBAC Reader, Writer, or Admin role. Do not grant Cluster Admin to application teams."
  }
}

variable "app_deployer_service_principal_object_id" {
  type        = string
  description = "Optional object ID of the GitHub Actions app-deployment service principal (enterprise application)."
  default     = "030d15d8-1da1-43ec-a3ce-62902b5c8c26"
  nullable    = true
}

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D2ds_v6"
}

variable "user_node_pools" {
  type = map(object({
    vm_size   = string
    min_count = number
    max_count = number
    zones     = optional(list(string), [])
  }))
  default = {
    user = {
      vm_size   = "Standard_D2ds_v6"
      min_count = 1
      max_count = 1
    }
  }
}

variable "runner_vm_size" {
  type        = string
  description = "Azure VM size for the private self-hosted GitHub Actions runner."
  default     = "Standard_D2ds_v6"
}

variable "runner_availability_zone" {
  type        = string
  description = "Optional availability zone for the runner VM. Set null when zones are unavailable."
  default     = null
  nullable    = true
}

variable "runner_admin_ssh_public_key" {
  type        = string
  description = "SSH public key used for private administration of the runner VM."

  validation {
    condition     = can(regex("^(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521) ", trimspace(var.runner_admin_ssh_public_key)))
    error_message = "runner_admin_ssh_public_key must be a valid-format SSH public key."
  }
}

variable "github_repository" {
  type        = string
  description = "GitHub repository in owner/repository form for OIDC federation."
}

variable "github_branch" {
  type    = string
  default = "main"
}
