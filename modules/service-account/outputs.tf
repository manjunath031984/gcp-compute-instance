output "email" {
  description = "The email address of the created service account."
  value       = google_service_account.this.email
}

output "account_id" {
  description = "The service account ID."
  value       = google_service_account.this.account_id
}

output "service_account_key" {
  description = "The generated service account JSON key for the new service account."
  value       = google_service_account_key.this.private_key
  sensitive   = true
}
