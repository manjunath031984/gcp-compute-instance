# Environment-specific values for the development deployment.
project_id           = "gcp-dev-july-2026"
region               = "us-central1"
zone                 = "us-central1-a"
credentials_file     = "gcp-sa-key.json"
instance_name        = "compute-instance-demo"
machine_type         = "e2-medium"
boot_disk_size       = 30
image                = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
network              = "default"
subnetwork           = "default"
service_account_name = "gcp-compute-instance"
