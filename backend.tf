terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "dev/terraform"
  }
}
