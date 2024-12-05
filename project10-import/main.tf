provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

resource "azurerm_virtual_machine" "example" {
  name                  = "test"
  location              = "australiaeast"
  resource_group_name   = "ARMtemplate"
  vm_size               = "Standard_B1s"
  network_interface_ids = [
    "/subscriptions/f78b1160-ac53-46e6-b77c-be73847ecb68/resourceGroups/ARMtemplate/providers/Microsoft.Network/networkInterfaces/test989"
  ]

  storage_image_reference {
    offer     = "vm-ban-lin-ubuntu-1804"
    publisher = "bansirllc1619470302579"
    sku       = "ubuntu1804"
    version   = "latest"
  }
      plan {
        name      = "ubuntu1804"
        product   = "vm-ban-lin-ubuntu-1804"
        publisher = "bansirllc1619470302579"
    }

  storage_os_disk {
    name              = "test_OsDisk_1_6bd26f709b6248048774aacce7170bee"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = 30
  }

  os_profile {
    computer_name  = "test"
    admin_username = "sysadmin"
    admin_password = "Himanshu@2001" 
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled = true
    storage_uri = "https://webstoring.blob.core.windows.net/"
  }

  tags = {
    Environment = "Development"
  }
}
