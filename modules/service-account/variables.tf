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

variable "labels" {
  description = "Labels applied to the service account."
  type        = map(string)
  default     = {}
}
