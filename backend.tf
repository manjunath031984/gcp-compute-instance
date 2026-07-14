terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026"
    prefix = "dev/terraform"
  }
}
