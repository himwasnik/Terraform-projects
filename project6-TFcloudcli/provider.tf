terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "backend_him"

    workspaces {
      name = "terraformcli"
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