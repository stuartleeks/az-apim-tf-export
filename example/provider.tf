terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">=1.15"
    }
  }
}

provider "azurerm" {
  features {
  }
}