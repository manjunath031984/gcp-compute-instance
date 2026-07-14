# Validate that required APIs are enabled in the target project.
data "google_project" "project" {
  project_id = var.project_id
}

resource "null_resource" "api_validation" {
  depends_on = [data.google_project.project]

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      for api in ${join(" ", var.required_apis)}; do
        if ! gcloud services list --project=${var.project_id} --enabled --format="value(config.name)" | grep -qx "$api"; then
          echo "ERROR: Required API $api is not enabled"
          exit 1
        fi
      done
    EOT
    interpreter = ["bash", "-c"]
  }
}
