#Need to redeploy
resource "azurerm_resource_group" "this" {
  name     = local.names.resource_group
  location = var.location
  tags     = local.tags
}

module "network" {
  source = "./modules/network"

  name                           = local.names.vnet
  location                       = var.location
  resource_group_name            = azurerm_resource_group.this.name
  address_space                  = var.vnet_address_space
  aks_subnet_address_prefixes    = var.aks_subnet_address_prefixes
  node_subnet_address_prefixes   = var.node_subnet_address_prefixes
  runner_subnet_address_prefixes = var.runner_subnet_address_prefixes
  tags                           = local.tags
}

module "aks" {
  source = "./modules/aks"

  name                   = local.names.aks
  location               = var.location
  resource_group_id      = azurerm_resource_group.this.id
  kubernetes_version     = null
  subnet_id              = module.network.aks_subnet_id
  service_cidr           = var.service_cidr
  dns_service_ip         = var.dns_service_ip
  admin_group_object_ids = var.admin_group_object_ids
  system_node_vm_size    = var.system_node_vm_size
  user_node_pools        = var.user_node_pools
  github_repository      = var.github_repository
  github_branch          = var.github_branch
  tags                   = local.tags
}

module "runner_vm" {
  source = "./modules/runner-vm"

  name                 = local.names.runner_vm
  location             = var.location
  resource_group_name  = azurerm_resource_group.this.name
  subnet_id            = module.network.runner_subnet_id
  vm_size              = var.runner_vm_size
  availability_zone    = var.runner_availability_zone
  admin_ssh_public_key = var.runner_admin_ssh_public_key
  tags                 = local.tags
}

module "acr" {
  source  = "Azure/avm-res-containerregistry-registry/azurerm"
  version = "0.8.0"

  name                          = local.names.acr
  resource_group_name           = azurerm_resource_group.this.name
  location                      = var.location
  sku                           = "Basic"
  admin_enabled                 = false
  zone_redundancy_enabled       = false
  public_network_access_enabled = true
  tags                          = local.tags
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.resource_id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity.objectId
  principal_type       = "ServicePrincipal"
}

resource "azurerm_role_assignment" "namespace_access" {
  for_each = var.namespace_access

  scope                = "${module.aks.id}/namespaces/${each.value.namespace}"
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.service_principal_object_id != null ? each.value.service_principal_object_id : each.value.entra_group_object_id
  principal_type       = each.value.service_principal_object_id != null ? "ServicePrincipal" : "Group"
}

resource "azurerm_role_assignment" "app_deployer_cluster_user" {
  count = var.app_deployer_service_principal_object_id == null ? 0 : 1

  scope                = module.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.app_deployer_service_principal_object_id
  principal_type       = "ServicePrincipal"
}
