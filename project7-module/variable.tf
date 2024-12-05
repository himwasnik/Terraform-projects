variable "subscription_id" {
  description = "The Azure subscription ID"
}

variable "client_id" {
  description = "The Azure client ID"
}

variable "client_secret" {
  description = "The Azure client secret"
  sensitive   = true
}

variable "tenant_id" {
  description = "The Azure tenant ID"
}
