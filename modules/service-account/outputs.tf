# Outputs for the service account module.
output "email" {
  description = "The email address of the service account."
  value       = google_service_account.this.email
}

output "unique_id" {
  description = "The unique ID of the service account."
  value       = google_service_account.this.unique_id
}

output "id" {
  description = "The fully qualified resource ID of the service account."
  value       = google_service_account.this.id
}
