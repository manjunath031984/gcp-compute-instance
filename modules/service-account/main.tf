# Create a dedicated service account for the compute instance workload.
resource "google_service_account" "this" {
  account_id   = var.service_account_name
  project      = var.project_id
  display_name = var.display_name
  description  = "Service account for compute instance operations."
  labels       = var.labels
}

# Generate a new service account key in JSON format.
resource "google_service_account_key" "this" {
  service_account_id = google_service_account.this.name
  key_algorithm      = "KEY_ALG_RSA_2048"
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}
