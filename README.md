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

Create a service account and download the JSON key file. Store it as a Jenkins credential with ID `gcp-sa-key`.

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
2. **Terraform Format** - Validate code formatting
3. **Terraform Init** - Initialize Terraform with GCS backend
4. **Terraform Validate** - Validate Terraform configuration
5. **Enable GCP APIs** - Enable required APIs
6. **Terraform Plan (IAM)** - Plan service account and IAM roles
7. **Terraform Apply (IAM)** - Apply service account and IAM roles
8. **IAM Validation** - Verify service account and roles are created
9. **Manual Approval** - Require manual approval before VM creation
10. **Terraform Plan (Compute)** - Plan VM instance creation
11. **Terraform Apply (Compute)** - Create VM instance
12. **VM Verification** - Verify VM is running and properly configured
13. **Terraform Outputs** - Display infrastructure outputs
14. **Cleanup** - Clean up temporary plan files
15. **Optional Destroy** - Optionally destroy all infrastructure

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
- **service_account_key**: JSON key of the service account (sensitive)
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
