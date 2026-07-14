# Shared local values and standard labels for the environment.
locals {
  environment = "dev"
  application = "terraform-demo"
  owner       = "DevOps"

  common_labels = merge(
    {
      environment = local.environment
      application = local.application
      owner       = local.owner
    },
    var.labels
  )
}
