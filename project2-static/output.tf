output "public_ip_address" {
  value = data.azurerm_public_ip.existing_public_ip.ip_address
}

output "azurerm_network_interface" {
  value = resource.azurerm_network_interface.example.name
}