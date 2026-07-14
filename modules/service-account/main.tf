# Service account module that creates a dedicated account for the VM.
resource "google_service_account" "this" {
  account_id   = var.service_account_name
  display_name = var.display_name
  project      = var.project_id
  description  = "Managed by Terraform for the compute instance workload."
}
