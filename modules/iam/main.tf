# Assign required IAM roles to the compute instance service account.
resource "google_project_iam_member" "this" {
  for_each = toset(var.required_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${var.service_account_email}"
}
