output "service_account_email" {
  description = "Email address of the gcp-compute-instance service account."
  value       = module.service_account.email
}

output "service_account_name" {
  description = "Service account ID created for the deployment."
  value       = module.service_account.account_id
}

output "service_account_key" {
  description = "Generated JSON key for the new service account."
  value       = module.service_account.service_account_key
  sensitive   = true
}

output "instance_name" {
  description = "Compute Engine instance name."
  value       = module.compute_instance.name
}

output "instance_zone" {
  description = "Compute Engine instance zone."
  value       = module.compute_instance.zone
}

output "instance_external_ip" {
  description = "External IP assigned to the compute instance."
  value       = module.compute_instance.external_ip
}

output "service_account_scopes" {
  description = "OAuth scopes assigned to the compute instance."
  value       = module.compute_instance.service_account_scopes
}
