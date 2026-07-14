# terraform-gcp-compute-instance

This project provisions a production-ready Google Compute Engine instance with a dedicated service account, IAM roles, and Terraform-managed state stored in Google Cloud Storage.

## Architecture

The solution uses a layered Terraform structure:

- Root module for orchestration and shared values
- Reusable modules for service account, IAM, and compute instance provisioning
- Remote state stored in a Google Cloud Storage bucket

## Folder Structure

```text
terraform-gcp-compute-instance/
├── versions.tf
├── provider.tf
├── remote-state.tf
├── variables.tf
├── locals.tf
├── main.tf
├── outputs.tf
├── dev.tfvars
├── README.md
├── Jenkinsfile
└── modules
    ├── service-account
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── compute-instance
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

## Prerequisites

- Terraform >= 1.13
- Google Cloud SDK configured with access
- A service account JSON key file named gcp-sa-key.json
- Permission to create compute instances, service accounts, IAM bindings, and GCS buckets

## Authentication

Authentication is performed using the service account JSON key file specified in the provider configuration:

```hcl
provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}
```

## Terraform Commands

```bash
terraform init
terraform plan -var-file=dev.tfvars -out=tfplan
terraform apply -auto-approve tfplan
terraform output
```

## Jenkins Pipeline

The repository includes a Declarative Jenkins pipeline that performs formatting, initialization, validation, planning, manual approval, apply, output retrieval, and cleanup.

## Module Description

- service-account: Creates a dedicated service account with labels.
- iam: Grants the required IAM roles to the service account.
- compute-instance: Provisions the Ubuntu-based virtual machine with startup configuration.

## Outputs

The root module exposes outputs for the instance name, IDs, IP addresses, and service account email.

## Troubleshooting

- Ensure the service account key file exists and is readable.
- Verify the target project and billing are enabled.
- Ensure the state bucket exists and the service account has object admin access to it.
- Review Terraform plan output carefully before apply.

## Best Practices

- Use variables and tfvars for environment-specific values.
- Keep modules reusable and focused on a single concern.
- Use labels consistently for governance and cost allocation.
- Keep dependencies explicit.
- Validate and format Terraform code before deployment.
