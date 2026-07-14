# Outputs for the service account module.
output "email" {
  description = "The email address of the service account."
  value       = local.service_account.email
}

output "unique_id" {
  description = "The unique ID of the service account."
  value       = local.service_account.unique_id
}

output "id" {
  description = "The fully qualified resource ID of the service account."
  value       = local.service_account.id
}
