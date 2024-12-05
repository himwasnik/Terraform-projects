variable "client_id" {
  description = "Client ID for the service principal"
  type        = string
  default = ""
}

variable "client_secret" {
  description = "Client Secret for the service principal"
  type        = string
}

variable "tenant_id" {
  description = "Tenant ID"
  type        = string
}

variable "subscription_id" {
  description = "Subscription ID"
  type        = string
}
variable "location" {
  type = string
}