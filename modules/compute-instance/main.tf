# Create a VPC network for the compute instance.
resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Custom VPC for the compute instance deployment."
}

# Create a subnet inside the VPC.
resource "google_compute_subnetwork" "this" {
  name          = var.subnetwork_name
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.this.self_link
  ip_cidr_range = var.subnetwork_ip_cidr
  description   = "Subnet for the compute instance."
}

# Firewall to allow SSH access.
resource "google_compute_firewall" "ssh" {
  name    = "${var.network_name}-allow-ssh"
  project = var.project_id
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.tags
  description   = "Allow SSH access to the compute instance."
}

# Reserved static external IP for the instance.
resource "google_compute_address" "static_ip" {
  name    = "${var.instance_name}-external-ip"
  project = var.project_id
  region  = var.region
}

# Compute instance definition.
resource "google_compute_instance" "this" {
  name         = var.instance_name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/${var.image_family}"
      size  = var.boot_disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
    network    = google_compute_network.this.self_link
    subnetwork = google_compute_subnetwork.this.self_link

    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  labels   = var.labels
  tags     = var.tags
  metadata = var.metadata

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }
}

output "name" {
  description = "Name of the created compute instance."
  value       = google_compute_instance.this.name
}

output "zone" {
  description = "Zone where the compute instance is deployed."
  value       = google_compute_instance.this.zone
}

output "external_ip" {
  description = "Static external IP assigned to the compute instance."
  value       = google_compute_address.static_ip.address
}

output "service_account_scopes" {
  description = "OAuth scopes assigned to the compute instance service account."
  value       = google_compute_instance.this.service_account[0].scopes
}
