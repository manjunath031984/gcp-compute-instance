# Outputs for the IAM module.
output "assigned_roles" {
  description = "The IAM roles assigned to the service account."
  value       = var.roles
}
