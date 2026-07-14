locals {
  common_labels = merge(
    var.project_labels,
    {
      environment = var.environment
      deployment  = "terraform-gcp"
    }
  )
}

module "validation" {
  source        = "./modules/validation"
  project_id    = var.project_id
  required_apis = var.required_apis
}

module "service_account" {
  source               = "./modules/service-account"
  project_id           = var.project_id
  service_account_name = var.service_account_name
  display_name         = "GCP Compute Instance Service Account"
  labels               = local.common_labels
}

module "iam" {
  source                = "./modules/iam"
  project_id            = var.project_id
  service_account_email = module.service_account.email
  required_roles        = var.required_roles
  labels                = local.common_labels
  depends_on            = [module.service_account, module.validation]
}

module "compute_instance" {
  source                 = "./modules/compute-instance"
  project_id             = var.project_id
  region                 = var.region
  zone                   = var.zone
  instance_name          = var.instance_name
  machine_type           = var.machine_type
  boot_disk_size_gb      = var.boot_disk_size_gb
  boot_disk_type         = var.boot_disk_type
  image_family           = var.image_family
  network_name           = var.network_name
  subnetwork_name        = var.subnetwork_name
  subnetwork_ip_cidr     = var.subnetwork_ip_cidr_range
  service_account_email  = module.service_account.email
  tags                   = var.tags
  metadata               = var.metadata
  labels                 = local.common_labels
  depends_on             = [module.iam, module.validation]
}
