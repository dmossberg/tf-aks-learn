terraform {
  backend "local" {}
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 3.30.0"
    }
    http = {
      source = "hashicorp/http"
      version = ">= 3.2.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.15.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

provider "azurerm" {
  features {}
}
