terraform {
  required_version = ">= 1.10.0"

  backend "azurerm" {
    use_oidc         = true
    use_azuread_auth = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
