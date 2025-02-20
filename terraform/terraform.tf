terraform {
  backend "azurerm" {

  }

  required_providers {
    azurerm = {
      version = "4.20.0"
    }
  }
}

provider "azurerm" {
  features {}
}
