# Input variables for the Terraform configuration.
variable "project_id" {
  description = "The Google Cloud project identifier."
  type        = string
}

variable "region" {
  description = "The default Google Cloud region for resources."
  type        = string
}

variable "zone" {
  description = "The default Google Cloud zone for zonal resources."
  type        = string
}

variable "credentials_file" {
  description = "Path to the service account JSON credentials file."
  type        = string
}

variable "instance_name" {
  description = "Name of the compute instance."
  type        = string
  default     = "compute-instance-demo"
}

variable "machine_type" {
  description = "Machine type for the compute instance."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size" {
  description = "Boot disk size in GB."
  type        = number
  default     = 30
}

variable "image" {
  description = "The disk image to use for the boot disk."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "network" {
  description = "The network to attach the instance to."
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "The subnetwork to attach the instance to."
  type        = string
  default     = "default"
}

variable "tags" {
  description = "Network tags applied to the compute instance."
  type        = list(string)
  default     = ["ssh", "http", "https"]
}

variable "labels" {
  description = "Additional labels applied to the managed resources."
  type        = map(string)
  default     = {}
}

variable "service_account_name" {
  description = "Name of the service account used by the compute instance."
  type        = string
  default     = "gcp-compute-instance"
}

variable "use_existing_service_account" {
  description = "If true, use an existing service account with the given name instead of creating a new one."
  type        = bool
  default     = false
}
