locals {
  vnet_name = "${var.aks_rg_name}-vnet"
}

resource "azurerm_virtual_network" "aks-vnet" {
  address_space       = ["10.240.0.0/20"]
  location            = var.region
  name                = local.vnet_name
  resource_group_name = var.aks_rg_name
  depends_on = [
    azurerm_resource_group.aks-rg,
  ]
}

resource "azurerm_subnet" "aks-subnet" {
  address_prefixes     = ["10.240.0.0/22"]
  name                 = "default"
  resource_group_name  = var.aks_rg_name
  virtual_network_name = local.vnet_name
  depends_on = [
    azurerm_virtual_network.aks-vnet,
  ]
}

resource "azurerm_subnet" "aks-pod-subnet" {
  address_prefixes     = ["10.240.4.0/22"]
  name                 = "pod-subnet"
  resource_group_name  = var.aks_rg_name
  virtual_network_name = local.vnet_name

  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  depends_on = [
    azurerm_virtual_network.aks-vnet,
  ]
}

resource "azurerm_subnet" "private-link-subnet" {
  address_prefixes     = ["10.240.8.0/22"]
  name                 = "private-link-subnet"
  resource_group_name  = var.aks_rg_name
  virtual_network_name = local.vnet_name
  
  depends_on = [
    azurerm_virtual_network.aks-vnet,
  ]
}