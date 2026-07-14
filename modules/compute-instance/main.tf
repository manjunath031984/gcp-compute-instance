# Compute instance module that provisions a single Google Compute Engine VM.
resource "google_compute_instance" "this" {
  name                      = var.instance_name
  machine_type              = var.machine_type
  project                   = var.project_id
  zone                      = var.zone
  allow_stopping_for_update = true
  deletion_protection       = false
  labels                    = var.labels
  tags                      = var.tags

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.boot_disk_size
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      # Ephemeral public IP for external access.
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = var.service_account_scopes
  }

  metadata = var.metadata

  metadata_startup_script = var.startup_script

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
}
