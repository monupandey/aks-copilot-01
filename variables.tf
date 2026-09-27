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
  default     = "northeurope"
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
  default     = "cin"
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

variable "system_node_vm_size" {
  type    = string
  default = "Standard_D4ds_v5"
}

variable "user_node_pools" {
  type = map(object({
    vm_size   = string
    min_count = number
    max_count = number
    zones     = optional(list(string), ["1", "2", "3"])
  }))
  default = {
    user = {
      vm_size   = "Standard_D4ds_v5"
      min_count = 1
      max_count = 5
    }
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
