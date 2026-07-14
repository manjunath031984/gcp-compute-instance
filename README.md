# GCP Compute Instance with Terraform and Jenkins CI/CD

This repository contains a complete Terraform infrastructure-as-code project for provisioning a Google Cloud Platform (GCP) Compute Engine instance with automated CI/CD using Jenkins.

## Overview

This project demonstrates enterprise-grade infrastructure as code practices with:

- **Modular Terraform Architecture**: Reusable modules for validation, service accounts, IAM, and compute instances
- **Multi-Environment Support**: Dev, QA, and Production environments using Terraform workspaces
- **Jenkins CI/CD Pipeline**: Comprehensive pipeline with GCP API enablement, IAM setup, and VM verification
- **Security Best Practices**: Service account creation, IAM role management, and Shielded VM features
- **Infrastructure Validation**: Pre and post-deployment verification stages

## Prerequisites

- **GCP Account**: Active Google Cloud Project
- **Service Account**: GCP service account with appropriate permissions
- **Jenkins**: Jenkins instance with Terraform and gcloud CLI installed
- **Terraform**: Version 1.5+
- **Google Cloud SDK**: Latest version

## Project Structure

```
.
├── modules/
│   ├── compute-instance/     # VM instance module
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── iam/                  # IAM roles and bindings
│   │   ├── main.tf
│   │   └── variables.tf
│   ├── service-account/      # Service account creation
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── validation/           # API and prerequisites validation
│       ├── main.tf
│       └── variables.tf
├── terraform-gcp/            # Terraform working directory
│   ├── Jenkinsfile           # Jenkins pipeline definition
│   ├── main.tf               # Root module configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   ├── providers.tf          # Provider configuration
│   ├── versions.tf           # Terraform version requirements
│   ├── backend.tf            # Backend configuration
│   └── terraform.tfvars      # Variable values
├── Jenkinsfile               # Root Jenkins pipeline
├── README.md                 # This file
├── LICENSE                   # MIT License
└── .gitignore                # Git ignore rules
```

## Configuration

### Environment Variables

Set the following environment variables in Jenkins credentials or `.env`:

```bash
PROJECT_ID=gcp-dev-july-2026
REGION=us-central1
ZONE=us-central1-a
ENVIRONMENT=dev
BACKEND_BUCKET=gcp-dev-july-2026-terraform-state
```

### GCP Service Account

Create a service account and download the JSON key file. Store it as a Jenkins credential with ID `gcp-sa-key` unless you override `GCP_SA_CREDENTIAL_ID` in the Jenkins job.

### Jenkins Variables for GCP Auth Automation

The setup script and Jenkins stage use these environment variables:

```bash
JENKINS_URL=https://jenkins.example.com
JENKINS_USERNAME=jenkins-bot
JENKINS_API_TOKEN=xxxxxxxxxxxxxxxx
GOOGLE_CLOUD_PROJECT=gcp-dev-july-2026
GOOGLE_APPLICATION_CREDENTIALS=/path/to/bootstrap-auth.json
```

### Terraform Variables

Update `terraform-gcp/terraform.tfvars` with your specific values:

```hcl
project_id            = "your-gcp-project-id"
region                = "us-central1"
zone                  = "us-central1-a"
environment           = "dev"
service_account_name  = "gcp-compute-instance"
instance_name         = "gcp-compute-instance-dev"
machine_type          = "e2-medium"
boot_disk_size_gb     = 50
image_family          = "ubuntu-2404-lts"
```

## Pipeline Stages

The Jenkins pipeline executes the following stages:

1. **Checkout** - Clone repository from SCM
2. **Setup GCP Authentication** - Idempotently verifies/creates service account, rotates key, and updates Jenkins credential
3. **Agent TLS Preflight** - Checks gcloud runtime and TLS readiness for Google OAuth endpoints
4. **Authenticate to GCP** - Authenticates using Jenkins file credential
5. **Terraform Format** - Validate code formatting
6. **Terraform Init** - Initialize Terraform with GCS backend
7. **Terraform Validate** - Validate Terraform configuration
8. **Terraform Plan (IAM)** - Plan service account and IAM roles
9. **Terraform Apply (IAM)** - Apply service account and IAM roles
10. **IAM Validation** - Verify service account and roles are created
11. **Manual Approval** - Require manual approval before VM creation
12. **Terraform Plan (Compute)** - Plan VM instance creation
13. **Terraform Apply (Compute)** - Create VM instance
14. **VM Verification** - Verify VM is running and properly configured
15. **Terraform Outputs** - Display infrastructure outputs
16. **Cleanup** - Clean up temporary plan files
17. **Optional Destroy** - Optionally destroy all infrastructure

## GCP Service Account Automation Script

This repository includes [scripts/setup-gcp-service-account.sh](scripts/setup-gcp-service-account.sh) to automate complete GCP auth setup and Jenkins credential update for:

- Project: `gcp-dev-july-2026`
- Service account: `infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com`
- Jenkins credential ID: value of `JENKINS_CREDENTIAL_ID` or `gcp-sa-key` by default

The script is idempotent and safe for repeated execution.

### What It Does

1. Validates current gcloud authentication and active project context
2. Verifies project `gcp-dev-july-2026` exists
3. Reuses or creates service account `infra-admin`
4. Ensures required IAM roles are assigned without duplicate bindings
5. Deletes all old user-managed keys and creates exactly one new JSON key
6. Validates the new key by activating it and checking project + storage access
7. Backs up existing Jenkins credential (if present) under `backup/`
8. Creates or replaces the Jenkins Secret File credential selected by `JENKINS_CREDENTIAL_ID`
9. Verifies credential exists in Jenkins
10. Removes temporary key files securely

### Prerequisites

- `bash` (Linux-based Jenkins agent)
- `gcloud` CLI
- `python3`
- `curl`
- Jenkins credentials plugin with Secret File support
- Jenkins Secret File credential `gcp-sa-key` available to the pipeline, unless you set a different `GCP_SA_CREDENTIAL_ID`
- Jenkins credentials configured only if you enable credential rotation in the pipeline:
   - `jenkins-api-user` (Username with API token as password)
   - `jenkins-url` (String containing base Jenkins URL)

### Jenkins Pipeline Parameters

- `GCP_SA_CREDENTIAL_ID` defaults to `gcp-sa-key`
- `ROTATE_GCP_CREDENTIAL` defaults to `false`
- `JENKINS_API_CREDENTIAL_ID` defaults to `jenkins-api-user`
- `JENKINS_URL_CREDENTIAL_ID` defaults to `jenkins-url`

Normal Terraform runs only require the GCP file credential. Enable `ROTATE_GCP_CREDENTIAL` when you want the pipeline to regenerate the service account key and upsert the same Jenkins credential ID through the Jenkins REST API.

### Required IAM Permissions

The bootstrap identity running the script must be able to:

- View and configure project IAM policy (`resourcemanager.projects.getIamPolicy`, `setIamPolicy`)
- Create and view service accounts (`iam.serviceAccounts.create`, `get`)
- List/delete/create service account keys (`iam.serviceAccountKeys.list`, `delete`, `create`)
- Validate project and storage access (`resourcemanager.projects.get`, `storage.buckets.list`)

### Execute Manually

```bash
chmod +x scripts/setup-gcp-service-account.sh
export JENKINS_URL="https://jenkins.example.com"
export JENKINS_USERNAME="jenkins-bot"
export JENKINS_API_TOKEN="<api-token>"
export GOOGLE_CLOUD_PROJECT="gcp-dev-july-2026"
./scripts/setup-gcp-service-account.sh
```

### Expected Output

- Colored logs with `INFO`, `SUCCESS`, `WARNING`, and `ERROR`
- Confirmation of project and service account state
- IAM role assignment status per role
- Jenkins credential backup path when existing credential is found
- Final verification message for the selected Jenkins credential ID

### Rollback Procedure

If Jenkins credential update needs rollback:

1. Locate latest backup in `backup/` (timestamped XML)
2. Open Jenkins credential configuration UI
3. Restore previous credential content or recreate using backup metadata
4. Re-run pipeline starting from `Setup GCP Authentication` stage

If GCP key rotation needs rollback:

1. Generate a replacement key manually for `infra-admin`
2. Upload the key to the Jenkins credential referenced by `GCP_SA_CREDENTIAL_ID`
3. Validate with `gcloud auth activate-service-account --key-file=<key.json>`

### Troubleshooting

#### Common GCP Authentication Errors

- `TLSV1_ALERT_PROTOCOL_VERSION`
   - Cause: old TLS/OpenSSL runtime on Jenkins agent
   - Fix: upgrade Cloud SDK, Python/OpenSSL, and verify proxy supports TLS 1.2+

- `PERMISSION_DENIED` when creating SA or keys
   - Cause: bootstrap identity missing IAM permissions
   - Fix: grant required IAM roles to bootstrap identity

- `403` while listing buckets
   - Cause: key is valid but lacks storage permissions
   - Fix: ensure `roles/storage.admin` is attached

- Jenkins `403 No valid crumb`
   - Cause: missing/expired crumb token
   - Fix: verify `JENKINS_URL`, API token, and crumb issuer settings

- Jenkins credential not found after update
   - Cause: wrong credential domain/store or insufficient Jenkins permissions
   - Fix: grant credentials create/update rights and rerun script

## Running the Pipeline

### Jenkins Execution

1. Create a new Pipeline job in Jenkins
2. Point to this repository's Jenkinsfile
3. Configure the following parameters:
   - **ENVIRONMENT**: Select deployment environment (dev, qa, prod)
   - **DESTROY**: Enable to destroy infrastructure after deployment

4. Execute the build

### Manual Terraform Execution

```bash
cd terraform-gcp

# Initialize Terraform
terraform init

# Plan infrastructure
terraform plan -var-file=terraform.tfvars

# Apply infrastructure
terraform apply -var-file=terraform.tfvars

# View outputs
terraform output

# Destroy infrastructure
terraform destroy -var-file=terraform.tfvars
```

## Outputs

The pipeline provides the following outputs:

- **service_account_email**: Email address of the created service account
- **instance_id**: Compute Engine instance ID
- **instance_name**: Compute Engine instance name
- **instance_zone**: Zone where instance is deployed
- **internal_ip**: Internal IP address of the instance
- **external_ip**: External IP address of the instance
- **network_interface**: Network interface configuration

## Validation Stages

### Stage 4: IAM Validation

Verifies:
- ✓ Service Account exists
- ✓ Service Account key exists
- ✓ Required IAM roles are attached
- ✓ Required APIs are enabled

Terminates pipeline immediately if validation fails.

### Stage 6: VM Verification

Verifies:
- ✓ VM exists
- ✓ VM status is RUNNING
- ✓ Correct Service Account attached
- ✓ External IP assigned
- ✓ Network Interface configured

## Best Practices Implemented

- **Modular Architecture**: Reusable Terraform modules for each component
- **Variable Management**: All values externalized as variables
- **Module Dependencies**: Explicit `depends_on` for module ordering
- **Code Comments**: Comprehensive comments on all resources
- **Error Handling**: Explicit error checking and graceful failure
- **Multi-Environment**: Workspace support for multiple environments
- **State Management**: Remote state backend in GCS
- **Security**: Service accounts with minimal required permissions
- **Validation**: Pre and post-deployment verification
- **Logging**: Comprehensive Jenkins pipeline logging

## Terraform Best Practices

- Variables and outputs between modules
- Resource comments explaining purpose
- Proper resource naming conventions
- Explicit dependencies with `depends_on`
- No hardcoded values
- Type specifications for all variables
- Meaningful variable descriptions

## Troubleshooting

### API Not Enabled

If you get an error about an API not being enabled:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### Service Account Issues

Verify service account permissions:

```bash
gcloud iam service-accounts describe gcp-compute-instance@PROJECT_ID.iam.gserviceaccount.com
gcloud projects get-iam-policy PROJECT_ID --flatten="bindings[].members" --filter="bindings.members:serviceAccount:gcp-compute-instance@PROJECT_ID.iam.gserviceaccount.com"
```

### VM Creation Fails

Check Terraform logs:

```bash
cd terraform-gcp
TF_LOG=DEBUG terraform apply -var-file=terraform.tfvars
```

## Security Considerations

- Service account keys are sensitive - store securely in Jenkins credentials
- Use Shielded VMs for enhanced security
- Implement network firewall rules appropriately
- Regular audit of IAM roles and permissions
- Keep Terraform state file secure (encrypted in GCS backend)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions, please create an issue in the repository.

## Author

Created by Manjunath

## Links

- [Terraform Documentation](https://www.terraform.io/docs)
- [Google Cloud Terraform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [GCP Documentation](https://cloud.google.com/docs)
