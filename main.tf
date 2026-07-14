# Root module that instantiates the service account, IAM, and compute instance modules.
module "service_account" {
  source               = "./modules/service-account"
  project_id           = var.project_id
  service_account_name = var.service_account_name
  display_name         = "Compute Instance Service Account"
  labels               = local.common_labels
}

module "iam" {
  source                = "./modules/iam"
  project_id            = var.project_id
  service_account_email = module.service_account.email
  roles = [
    "roles/compute.admin",
    "roles/iam.serviceAccountUser",
    "roles/compute.osLogin",
    "roles/iap.tunnelResourceAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ]
  labels = local.common_labels

  depends_on = [module.service_account]
}

module "compute_instance" {
  source                 = "./modules/compute-instance"
  project_id             = var.project_id
  region                 = var.region
  zone                   = var.zone
  instance_name          = var.instance_name
  machine_type           = var.machine_type
  boot_disk_size         = var.boot_disk_size
  image                  = var.image
  network                = var.network
  subnetwork             = var.subnetwork
  tags                   = var.tags
  labels                 = local.common_labels
  service_account_email  = module.service_account.email
  service_account_scopes = ["cloud-platform"]
  metadata = {
    enable-oslogin = "TRUE"
  }
  startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail
    apt-get update
    apt-get install -y curl git unzip jq python3 python3-pip
    apt-get install -y ca-certificates curl gnupg lsb-release
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "Software installation completed successfully."
  EOT

  depends_on = [module.iam]
}
