terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

module "vm" {
  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  zone                = var.availability_zone
  os_type             = "Linux"
  sku_size            = var.vm_size

  account_credentials = {
    admin_credentials = {
      username                           = "runneradmin"
      ssh_keys                           = [var.admin_ssh_public_key]
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  network_interfaces = {
    runner_nic = {
      name = "${var.name}-nic"
      ip_configurations = {
        runner_ip = {
          name                          = "${var.name}-ipconfig"
          private_ip_subnet_resource_id = var.subnet_id
        }
      }
    }
  }

  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  encryption_at_host_enabled = true
  custom_data                = base64encode(file("${path.module}/cloud-init.yaml"))
  tags                       = var.tags
}

output "id" {
  value = module.vm.resource_id
}

output "private_ip" {
  value = module.vm.virtual_machine_azurerm["private_ip_address"]
}
