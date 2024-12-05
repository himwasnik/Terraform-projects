resource "azurerm_virtual_network" "main_vnet" {
  name                = "example-vnet"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  address_space       = ["11.0.0.0/20"]
}

resource "azurerm_subnet" "subnet1" {
  name                 = "subnet1"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main_vnet.name
  address_prefixes     = ["11.0.1.0/24"]
}
