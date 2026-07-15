# Ensure required APIs are enabled before dependent resources are created.
resource "google_project_service" "required" {
  for_each = toset(var.required_apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}
