variable "project_id" {
  description = "Google Cloud project ID for the compute instance resources."
  type        = string
}

variable "region" {
  description = "Google Cloud region for regional compute resources."
  type        = string
}

variable "zone" {
  description = "Google Cloud zone for the compute instance."
  type        = string
}

variable "instance_name" {
  description = "The compute instance name."
  type        = string
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
}

variable "boot_disk_type" {
  description = "Boot disk type for the compute instance."
  type        = string
}

variable "image_family" {
  description = "Ubuntu image family for the boot disk."
  type        = string
}

variable "network_name" {
  description = "VPC network name for the compute instance."
  type        = string
}

variable "subnetwork_name" {
  description = "Subnet name for the compute instance."
  type        = string
}

variable "subnetwork_ip_cidr" {
  description = "CIDR range for the compute instance subnet."
  type        = string
}

variable "service_account_email" {
  description = "Service account email attached to the compute instance."
  type        = string
}

variable "tags" {
  description = "Network tags assigned to the compute instance."
  type        = list(string)
}

variable "metadata" {
  description = "Metadata applied to the compute instance."
  type        = map(string)
}

variable "labels" {
  description = "Labels applied to the compute instance."
  type        = map(string)
  default     = {}
}
