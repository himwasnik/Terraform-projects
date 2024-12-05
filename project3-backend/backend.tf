terraform {
  backend "azurerm" {
    resource_group_name  = "Terraform-RG_be"
    storage_account_name = "webstoring"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    access_key = "iI3twPgv/XaVs2N8P4/WIyr9/YS5b+FaqDh7vm3jC1wjG3RjMgwfh/ZKv4lVuOwNH7M8KyvCc4uj+AStcB8qzQ=="
  }
}
