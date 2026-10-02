terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.8.1"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space

  subnets = {
    aks = {
      name             = "snet-aks-${var.name}"
      address_prefixes = var.aks_subnet_address_prefixes
      delegations      = []
    }
    nodes = {
      name             = "snet-nodes-${var.name}"
      address_prefixes = var.node_subnet_address_prefixes
      delegations      = []
    }
    runner = {
      name             = "snet-runner-${var.name}"
      address_prefixes = var.runner_subnet_address_prefixes
      delegations      = []
    }
  }

  tags = var.tags
}

output "vnet_id" {
  value = module.vnet.resource.id
}

output "aks_subnet_id" {
  value = module.vnet.subnets["aks"].resource_id
}

output "runner_subnet_id" {
  value = module.vnet.subnets["runner"].resource_id
}
