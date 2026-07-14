# Service account module that creates a dedicated account for the VM.
resource "google_service_account" "this" {
  count        = var.use_existing_service_account ? 0 : 1
  account_id   = var.service_account_name
  display_name = var.display_name
  project      = var.project_id
  description  = "Managed by Terraform for the compute instance workload."
}

data "google_service_account" "existing" {
  count      = var.use_existing_service_account ? 1 : 0
  project    = var.project_id
  account_id = var.service_account_name
}

locals {
  service_account = var.use_existing_service_account ? data.google_service_account.existing[0] : google_service_account.this[0]
}
