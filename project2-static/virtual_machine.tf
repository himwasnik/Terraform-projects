data "azurerm_virtual_network" "existing_vnet" {
  name                = "chatappVnet"
  resource_group_name = "ARMtemplate"
}

data "azurerm_subnet" "existing_subnet" {
  name                 = "subnet1" 
  virtual_network_name = data.azurerm_virtual_network.existing_vnet.name
  resource_group_name  = "ARMtemplate"
}

data "azurerm_public_ip" "existing_public_ip" {
  name                = "example-ip" 
  resource_group_name = "ARMtemplate"
}

resource "azurerm_network_interface" "example" {
  name                = "example-niccc"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.existing_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.existing_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "example" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  size                = "Standard_F2"
  admin_username      = "sysadmin"
  admin_password      = "Himanshu@2001"

  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}