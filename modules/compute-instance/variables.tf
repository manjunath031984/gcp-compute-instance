# Variables for the compute instance module.
variable "project_id" {
  description = "The Google Cloud project identifier."
  type        = string
}

variable "region" {
  description = "The Google Cloud region for the instance."
  type        = string
}

variable "zone" {
  description = "The Google Cloud zone for the instance."
  type        = string
}

variable "instance_name" {
  description = "Name of the compute instance."
  type        = string
}

variable "machine_type" {
  description = "Machine type of the compute instance."
  type        = string
}

variable "boot_disk_size" {
  description = "Boot disk size in GB."
  type        = number
}

variable "image" {
  description = "Boot disk image to use."
  type        = string
}

variable "network" {
  description = "Network to attach the instance to."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork to attach the instance to."
  type        = string
}

variable "tags" {
  description = "Network tags for the instance."
  type        = list(string)
}

variable "labels" {
  description = "Labels applied to the compute instance."
  type        = map(string)
  default     = {}
}

variable "service_account_email" {
  description = "Email address of the service account attached to the instance."
  type        = string
}

variable "service_account_scopes" {
  description = "OAuth scopes assigned to the service account on the instance."
  type        = list(string)
}

variable "metadata" {
  description = "Metadata key/value pairs applied to the instance."
  type        = map(string)
  default     = {}
}

variable "startup_script" {
  description = "Startup script executed when the instance boots."
  type        = string
  default     = ""
}
