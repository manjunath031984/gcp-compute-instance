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
├── Dockerfile
├── docker-compose.yml
├── init_create_credentials.groovy
├── init_create_job.groovy
├── init_install_plugins.groovy
├── plugins.txt
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

## Jenkins Docker Deployment

A production-ready Jenkins image can be built using the included `Dockerfile` and `docker-compose.yml`.

1. Build the image:

```bash
docker build -t jenkins-terraform-gcp:1.1 .
```

2. Start Jenkins:

```bash
docker compose up -d
```

3. Install required plugins using the Jenkins script console or initialization scripts.

4. Create credentials and the pipeline job using the provided Groovy scripts:

```bash
# Run scripts in Jenkins script console or initialize Groovy jobs on startup.
```

## Jenkins Initialization Scripts

- `plugins.txt` - Plugin list for Jenkins installation.
- `init_install_plugins.groovy` - Installs missing plugins automatically.
- `init_create_credentials.groovy` - Creates GCP and GitHub credentials in Jenkins.
- `init_create_job.groovy` - Creates the `gcp-compute-instance` pipeline job.

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

### Invalid JWT Signature / oauth2 errors

- If you see errors like `invalid_grant` or `Invalid JWT Signature` when Terraform initializes the GCS backend, the service account key used for authentication is invalid or malformed.
- Common fixes:
  - Recreate and download a fresh JSON key from the GCP Console (IAM → Service Accounts → Keys → Create Key → JSON) and replace `gcp-sa-key.json`.
  - Ensure the `private_key` field begins with `-----BEGIN PRIVATE KEY-----` and ends with `-----END PRIVATE KEY-----` and was not truncated or modified by copy/paste.
  - Validate the key file locally using the included script:

```bash
python scripts/validate_gcp_key.py gcp-sa-key.json
```

- Recommended Jenkins setup:
  - Create a Jenkins `File` credential with ID `gcp-sa-key` and upload the JSON key there.
  - Alternatively, set the environment variable `GCP_SA_KEY_JSON` on the Jenkins master/agent to the full JSON contents (use with care).

If you prefer not to store a JSON key, consider using Workload Identity or running agents on GCP with attached service accounts.

## Best Practices

- Use variables and tfvars for environment-specific values.
- Keep modules reusable and focused on a single concern.
- Use labels consistently for governance and cost allocation.
- Keep dependencies explicit.
- Validate and format Terraform code before deployment.
