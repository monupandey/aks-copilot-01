locals {
  name_prefix = "${var.workload}-${var.region_code}-${var.environment}-${var.random_identifier}-${var.instance}"

  names = {
    resource_group = "rg-${local.name_prefix}"
    vnet           = "vnet-${local.name_prefix}"
    aks            = "aks-${local.name_prefix}"
    user_identity  = "uai-${local.name_prefix}"
    key_vault      = "kv-${local.name_prefix}"
    acr            = "acr${var.workload}${var.region_code}${var.environment}${var.random_identifier}${var.instance}"
  }

  tags = {
    workload    = var.workload
    environment = var.environment
    managed_by  = "terraform"
    repository  = var.github_repository
  }
}
