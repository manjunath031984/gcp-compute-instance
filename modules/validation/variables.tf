variable "project_id" {
  description = "Google Cloud project ID to validate."
  type        = string
}

variable "required_apis" {
  description = "List of APIs that must be enabled."
  type        = list(string)
}
