variable "project_id" {
  description = "Google Cloud project ID where the service account is created."
  type        = string
}

variable "service_account_name" {
  description = "Unique ID for the service account."
  type        = string
}

variable "display_name" {
  description = "Human-friendly service account display name."
  type        = string
}

variable "labels" {
  description = "Labels to apply to the service account."
  type        = map(string)
  default     = {}
}
