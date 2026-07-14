# Output values for the deployed resources.
output "instance_name" {
  description = "The name of the compute instance."
  value       = module.compute_instance.instance_name
}

output "instance_id" {
  description = "The generated ID of the compute instance."
  value       = module.compute_instance.instance_id
}

output "instance_self_link" {
  description = "The self link of the compute instance."
  value       = module.compute_instance.instance_self_link
}

output "external_ip" {
  description = "The external IP address assigned to the instance."
  value       = module.compute_instance.external_ip
}

output "internal_ip" {
  description = "The internal IP address assigned to the instance."
  value       = module.compute_instance.internal_ip
}

output "service_account_email" {
  description = "The email address of the service account."
  value       = module.service_account.email
}

output "zone" {
  description = "The zone where the instance resides."
  value       = var.zone
}

output "machine_type" {
  description = "The machine type of the compute instance."
  value       = var.machine_type
}
