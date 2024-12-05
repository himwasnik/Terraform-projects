# Terraform Provider Configuration
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.12.0"
    }
  }
}

provider "azurerm" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
  features {}
}

# Resource Group
resource "azurerm_resource_group" "chatapp_rg" {
  name     = "${terraform.workspace}-Terraform-chatapp"
  location = var.location
}

# virtual network
resource "azurerm_virtual_network" "chatapp_vnet" {
  name                = "${terraform.workspace}-chatapp-vnet"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "frontend_subnet" {
  name                 = "${terraform.workspace}-frontend-subnet"
  resource_group_name  = azurerm_resource_group.chatapp_rg.name
  virtual_network_name = azurerm_virtual_network.chatapp_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend_subnet" {
  name                 = "${terraform.workspace}-backend-subnet"
  resource_group_name  = azurerm_resource_group.chatapp_rg.name
  virtual_network_name = azurerm_virtual_network.chatapp_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "database_subnet" {
  name                 = "${terraform.workspace}-database-subnet"
  resource_group_name  = azurerm_resource_group.chatapp_rg.name
  virtual_network_name = azurerm_virtual_network.chatapp_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# Application Gateway Subnet - Separate Subnet for Application Gateway
resource "azurerm_subnet" "application_gateway_subnet" {
  name                 = "${terraform.workspace}-application-gateway-subnet"
  resource_group_name  = azurerm_resource_group.chatapp_rg.name
  virtual_network_name = azurerm_virtual_network.chatapp_vnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

# Backend Load Balancer
resource "azurerm_public_ip" "backend_lb_pip" {
  name                = "${terraform.workspace}-backend-lb-pip"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "backend_lb" {
  name                = "${terraform.workspace}-backend-lb"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "backend-frontend-ip"
    public_ip_address_id = azurerm_public_ip.backend_lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "${terraform.workspace}-backend-pool"
  loadbalancer_id     = azurerm_lb.backend_lb.id
}

resource "azurerm_lb_probe" "backend_probe" {
  name                = "${terraform.workspace}-backend-probe"
  loadbalancer_id     = azurerm_lb.backend_lb.id
  protocol            = "Http"
  port                = 80
  request_path        = "/health"
}

resource "azurerm_lb_rule" "backend_lb_rule" {
  name                           = "${terraform.workspace}-backend-rule"
  loadbalancer_id                = azurerm_lb.backend_lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "backend-frontend-ip"
  probe_id                       = azurerm_lb_probe.backend_probe.id
}

# 1. Create a Network Security Group (NSG)
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "${terraform.workspace}-frontend-nsg"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "frontend_vmss_pip" {
  name                = "${terraform.workspace}-frontend-vmss-pip"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "backend-nsg-${terraform.workspace}"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_subnet_network_security_group_association" "backend_subnet_nsg" {
  subnet_id                 = azurerm_subnet.backend_subnet.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_network_security_group" "database_vm_nsg" {
  name                = "database-vm-nsg-${terraform.workspace}"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name

  security_rule {
    name                       = "AllowMySQL"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "3306"  
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowSSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "22" 
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "database_vm_nic_nsg_association" {
  network_interface_id    = azurerm_network_interface.database_vm_nic.id
  network_security_group_id = azurerm_network_security_group.database_vm_nsg.id
}


# Frontend Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "frontend_vmss" {
  name                = "frontend-vmss"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  sku                 = "Standard_B1ls"
  instances           = 1
  admin_username      = "sysadmin"
  admin_password      = "Himanshu@2001"
  disable_password_authentication = false

  source_image_id = "/subscriptions/f78b1160-ac53-46e6-b77c-be73847ecb68/resourceGroups/MyInfra-RG/providers/Microsoft.Compute/galleries/gallary1/images/frontend1/versions/0.0.2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "frontend-nic"
    primary = true

    ip_configuration {
      name                                   = "frontend-ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.frontend_subnet.id
      //load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }
}

#backend vmss

resource "azurerm_linux_virtual_machine_scale_set" "backend_vmss" {
  name                = "backend-vmss"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  sku                 = "Standard_B1ls"
  instances           = 1
  admin_username      = "sysadmin"
  admin_password      = "Himanshu@2001"
  disable_password_authentication = false

  source_image_id = "/subscriptions/f78b1160-ac53-46e6-b77c-be73847ecb68/resourceGroups/MyInfra-RG/providers/Microsoft.Compute/galleries/gallary1/images/backend/versions/0.0.3"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
 plan {
    name      = "ubuntu1804"
    publisher = "bansirllc1619470302579"
    product   = "vm-ban-lin-ubuntu-1804"
  }


  network_interface {
    name    = "backend-nic"
    primary = true

    ip_configuration {
      name                                   = "backend-ipconfig"
      primary                                = true
      subnet_id                              = azurerm_subnet.backend_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }
}


# database vm
resource "azurerm_linux_virtual_machine" "database_vm" {
  name                  = "database-vm"
  location              = azurerm_resource_group.chatapp_rg.location
  resource_group_name   = azurerm_resource_group.chatapp_rg.name
  size                  = "Standard_B1ls"
  admin_username        = "sysadmin"
  admin_password        = "Himanshu@2001"
  disable_password_authentication = false

  # Specify the marketplace image directly
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface_ids = [
    azurerm_network_interface.database_vm_nic.id
  ]
}

resource "azurerm_network_interface" "database_vm_nic" {
  name                = "database-vm-nic"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name

  ip_configuration {
    name                          = "database-ipconfig"
    subnet_id                     = azurerm_subnet.database_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


# Frontend Application Gateway
resource "azurerm_public_ip" "frontend_pip" {
  name                = "frontend-pip"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "frontend_gateway" {
  name                = "frontend-gateway"
  location            = azurerm_resource_group.chatapp_rg.location
  resource_group_name = azurerm_resource_group.chatapp_rg.name
  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "frontend-gateway-ip"
    subnet_id = azurerm_subnet.application_gateway_subnet.id
  }

  frontend_ip_configuration {
    name                 = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.frontend_pip.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "frontend-backend-pool"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-public-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  backend_http_settings {
    name                  = "http-settings"
    protocol              = "Http"
    port                  = 80
    cookie_based_affinity = "Disabled"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    priority                   = 1 
    http_listener_name         = "http-listener"
    backend_http_settings_name = "http-settings"
    backend_address_pool_name  = "frontend-backend-pool"
  }
}
