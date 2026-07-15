variable "project_id" {
  description = "Google Cloud project ID for the deployment."
  type        = string
}

variable "region" {
  description = "Google Cloud region used for regional resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Google Cloud zone used for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Deployment environment name (dev, qa, prod)."
  type        = string
  default     = "dev"
}

variable "backend_bucket" {
  description = "GCS bucket used for Terraform remote state."
  type        = string
  default     = "YOUR_GCP_TF_STATE_BUCKET"
}

variable "service_account_email" {
  description = "Email address of the existing service account used by the compute instance."
  type        = string
  default     = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
}

variable "instance_name" {
  description = "Name of the compute engine instance."
  type        = string
  default     = "compute-instance-demo"
}

variable "machine_type" {
  description = "Compute Engine machine type."
  type        = string
  default     = "e2-medium"
}

variable "boot_disk_size_gb" {
  description = "Boot disk size in GB."
  type        = number
  default     = 50
}

variable "boot_disk_type" {
  description = "Boot disk type for the boot disk."
  type        = string
  default     = "pd-ssd"
}

variable "image_family" {
  description = "OS image family for the boot disk."
  type        = string
  default     = "ubuntu-2404-lts-amd64"
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
  default     = "gcp-vpc"
}

variable "subnetwork_name" {
  description = "Name of the subnet."
  type        = string
  default     = "gcp-subnet"
}

variable "subnetwork_ip_cidr_range" {
  description = "CIDR range for the subnet."
  type        = string
  default     = "10.10.0.0/24"
}

variable "firewall_allow_ssh" {
  description = "Whether SSH access is allowed to the VM."
  type        = bool
  default     = true
}

variable "firewall_allowed_ports" {
  description = "List of allowed inbound firewall ports."
  type        = list(number)
  default     = [22]
}

variable "tags" {
  description = "Network tags assigned to the compute instance."
  type        = list(string)
  default     = ["ssh"]
}

variable "metadata" {
  description = "Metadata applied to the compute instance."
  type        = map(string)
  default = {
    enable-oslogin = "TRUE"
  }
}

variable "required_apis" {
  description = "APIs that must be enabled prior to resource creation."
  type        = list(string)
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
  ]
}

variable "required_roles" {
  description = "IAM roles to assign to the compute service account."
  type        = list(string)
  default = [
    "roles/compute.admin",
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser",
    "roles/iam.serviceAccountTokenCreator",
    "roles/storage.admin",
    "roles/storage.objectAdmin",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/compute.networkAdmin",
    "roles/compute.securityAdmin",
    "roles/serviceusage.serviceUsageAdmin",
  ]
}

variable "project_labels" {
  description = "Labels for GCP resources in this environment."
  type        = map(string)
  default = {
    environment = "dev"
    owner       = "platform"
  }
}
