terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "4.14.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "e48488f6-0a23-407f-a401-2a2fe0ee69ab"
  features {}
}