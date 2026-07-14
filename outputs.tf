output "service_account_email" {
  description = "Email address of the existing service account attached to the compute instance."
  value       = var.service_account_email
}

output "service_account_name" {
  description = "Service account ID derived from the configured service account email."
  value       = split("@", var.service_account_email)[0]
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
