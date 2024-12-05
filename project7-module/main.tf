provider "azurerm" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

resource "azurerm_resource_group" "main_rg" {
  name     = "modules-resources"
  location = "Australia East"
}

module "virtual_machine" {
  source                  = "./modules/virtual_machine"
  resource_group_name     = azurerm_resource_group.main_rg.name
  resource_group_location = azurerm_resource_group.main_rg.location
}
module "virtual_network" {
  source = "./modules/virtual_network"
  resource_group_name     = azurerm_resource_group.main_rg.name
  resource_group_location = azurerm_resource_group.main_rg.location
}