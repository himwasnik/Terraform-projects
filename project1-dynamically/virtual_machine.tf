resource "azurerm_linux_virtual_machine" "main_vm" {
  name                = "example-vm"
  resource_group_name = azurerm_resource_group.main_rg.name
  location            = azurerm_resource_group.main_rg.location
  size                = "Standard_B1s"
  
  admin_username      = "adminuser"
  admin_password      = "Himanshu@2001" 

  network_interface_ids = [azurerm_network_interface.main_nic.id]
  
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
