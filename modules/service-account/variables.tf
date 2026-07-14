# Variables for the service account module.
variable "project_id" {
  description = "The Google Cloud project identifier."
  type        = string
}

variable "service_account_name" {
  description = "The unique account ID for the service account."
  type        = string
}

variable "display_name" {
  description = "Display name of the service account."
  type        = string
}

variable "use_existing_service_account" {
  description = "Set to true to use an existing service account with the given name instead of creating a new one."
  type        = bool
  default     = false
}
