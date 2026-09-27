resource "azurerm_resource_group" "this" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name                         = local.names.vnet
  location                     = var.location
  resource_group_name          = azurerm_resource_group.this.name
  address_space                = var.vnet_address_space
  aks_subnet_address_prefixes  = var.aks_subnet_address_prefixes
  node_subnet_address_prefixes = var.node_subnet_address_prefixes
  tags                         = local.tags
}

module "aks" {
  source = "./modules/aks"

  name                       = local.names.aks
  location                   = var.location
  resource_group_id          = azurerm_resource_group.this.id
  kubernetes_version         = null
  subnet_id                  = module.network.aks_subnet_id
  service_cidr               = var.service_cidr
  dns_service_ip             = var.dns_service_ip
  admin_group_object_ids     = var.admin_group_object_ids
  system_node_vm_size        = var.system_node_vm_size
  user_node_pools            = var.user_node_pools
  log_analytics_workspace_id = var.log_analytics_workspace_id
  github_repository          = var.github_repository
  github_branch              = var.github_branch
  tags                       = local.tags
}
