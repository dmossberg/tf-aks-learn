resource "azurerm_resource_group" "aks-rg" {
  location = var.region
  name     = var.aks_rg_name
}