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

output "acr_name" {
  value = module.acr.name
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "acr_id" {
  value = module.acr.resource_id
}

output "runner_vm_id" {
  value = module.runner_vm.id
}

output "runner_vm_private_ip" {
  value = module.runner_vm.private_ip
}

output "runner_subnet_id" {
  value = module.network.runner_subnet_id
}
