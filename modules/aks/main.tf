terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

module "aks" {
  source  = "Azure/avm-res-containerservice-managedcluster/azurerm"
  version = "0.4.0"

  name               = var.name
  location           = var.location
  parent_id          = var.resource_group_id
  dns_prefix         = var.name
  kubernetes_version = var.kubernetes_version
  sku = {
    name = "Base"
    tier = "Standard"
  }
  disable_local_accounts = true
  enable_rbac            = true
  managed_identities     = { system_assigned = true }
  aad_profile = {
    managed                = true
    enable_azure_rbac      = true
    admin_group_object_ids = var.admin_group_object_ids
  }
  api_server_access_profile = {
    enable_private_cluster = true
  }
  oidc_issuer_profile = {
    enabled = true
  }
  default_agent_pool = {
    name                = "system"
    vm_size             = var.system_node_vm_size
    vnet_subnet_id      = var.subnet_id
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    availability_zones  = ["1"]
    os_sku              = "AzureLinux"
    mode                = "System"
  }

  network_profile = {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    network_dataplane   = "azure"
    outbound_type       = "loadBalancer"
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  addon_profile_key_vault_secrets_provider = {
    enabled = true
    config = {
      enable_secret_rotation = true
    }
  }

  tags = var.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = substr(each.key, 0, 12)
  kubernetes_cluster_id = module.aks.resource_id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = var.subnet_id
  auto_scaling_enabled  = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  zones                 = each.value.zones
  mode                  = "User"
  os_sku                = "AzureLinux"
  node_labels = {
    workload = each.key
  }
}

output "id" {
  value = module.aks.resource_id
}

output "name" {
  value = module.aks.name
}
