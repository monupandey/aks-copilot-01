output "resource_group_name" {
  value = azurerm_resource_group.this.name
}

output "aks_id" {
  value = module.aks.id
}

output "aks_name" {
  value = module.aks.name
}

output "vnet_id" {
  value = module.network.vnet_id
}
