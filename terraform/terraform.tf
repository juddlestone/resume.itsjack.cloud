terraform {
  backend "azurerm" {

  }

  required_providers {
    azurerm = {
      version = "4.19.0"
    }
  }
}

provider "azurerm" {

}