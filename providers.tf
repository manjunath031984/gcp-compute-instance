provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "google" {
  alias   = "project"
  project = var.project_id
}
