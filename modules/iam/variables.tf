variable "project_id" {
  description = "Google Cloud project ID where IAM roles are assigned."
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account to bind IAM roles to."
  type        = string
}

variable "required_roles" {
  description = "List of IAM roles to attach to the service account."
  type        = list(string)
}

variable "labels" {
  description = "Labels to annotate IAM resources where supported."
  type        = map(string)
  default     = {}
}
