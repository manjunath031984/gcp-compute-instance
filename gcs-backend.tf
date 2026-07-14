# Backend configuration for storing Terraform state in Google Cloud Storage.
terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "dev"
  }
}
