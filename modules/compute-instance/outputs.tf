# Outputs for the compute instance module.
output "instance_name" {
  description = "The name of the compute instance."
  value       = google_compute_instance.this.name
}

output "instance_id" {
  description = "The generated ID of the compute instance."
  value       = google_compute_instance.this.id
}

output "instance_self_link" {
  description = "The self link of the compute instance."
  value       = google_compute_instance.this.self_link
}

output "external_ip" {
  description = "The external IP address of the instance."
  value       = google_compute_instance.this.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "The internal IP address of the instance."
  value       = google_compute_instance.this.network_interface[0].network_ip
}
