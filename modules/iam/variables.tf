# Variables for the IAM module.
variable "project_id" {
  description = "The Google Cloud project identifier."
  type        = string
}

variable "service_account_email" {
  description = "The service account email address to receive the roles."
  type        = string
}

variable "roles" {
  description = "List of IAM roles to assign to the service account."
  type        = list(string)
}

variable "labels" {
  description = "Labels applied to IAM resources where supported."
  type        = map(string)
  default     = {}
}
