# GCP Compute Instance with Terraform and Jenkins CI/CD

This repository contains a Terraform infrastructure-as-code project for provisioning a Google Cloud Platform (GCP) Compute Engine instance, its networking (VPC, subnet, firewall, static IP), and IAM role bindings, with automated CI/CD using Jenkins.

## Overview

This project demonstrates infrastructure as code practices with:

- **Modular Terraform Architecture**: Reusable modules for IAM and the compute instance/network
- **Jenkins CI/CD Pipeline**: Single parameterized pipeline supporting `apply` and `destroy` actions with a manual approval gate
- **Remote State**: Terraform state stored in a GCS backend
- **Security Practices**: Least-privilege IAM role bindings and Shielded VM features

## Prerequisites

- **GCP Account**: Active Google Cloud Project (`gcp-dev-july-2026` by default)
- **Service Account**: GCP service account key with permissions to manage IAM, Compute Engine, and the GCS state bucket
- **Jenkins**: Jenkins instance with Terraform and gcloud CLI installed
- **Terraform**: Version >= 1.13.0 (see [versions.tf](versions.tf))
- **Google Cloud SDK**: Latest version (for manual/local runs)

## Project Structure

```
.
├── backend.tf              # GCS remote state backend configuration
├── main.tf                 # Root module: wires up the iam and compute_instance modules
├── variables.tf             # Root input variables and defaults
├── outputs.tf               # Root output values
├── providers.tf             # Google provider configuration
├── versions.tf               # Terraform and provider version constraints
├── terraform.tfvars          # Variable values for this environment
├── Jenkinsfile               # Jenkins pipeline definition
├── gcp-sa-key                # Local GCP service account key (do not commit real keys)
├── LICENSE                   # MIT License
├── README.md                 # This file
└── modules/
    ├── compute-instance/     # VPC, subnet, firewall, static IP, and VM instance
    │   ├── main.tf
    │   └── variables.tf
    └── iam/                  # IAM role bindings for the service account
        ├── main.tf
        └── variables.tf
```

## Configuration

### Terraform Variables

Update [terraform.tfvars](terraform.tfvars) with your specific values:

```hcl
project_id               = "gcp-dev-july-2026"
region                   = "us-central1"
zone                     = "us-central1-a"
environment              = "dev"
backend_bucket           = "gcp-dev-july-2026-terraform-state"
service_account_email    = "infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
instance_name            = "compute-instance-demo"
network_name             = "gcp-vpc"
subnetwork_name          = "gcp-subnet"
subnetwork_ip_cidr_range = "10.10.0.0/24"
```

Other defaults (machine type, boot disk, required roles, tags, metadata, labels, etc.) are defined in [variables.tf](variables.tf) and can be overridden in `terraform.tfvars` or via `-var`.

### Backend Configuration

The GCS backend is configured in [backend.tf](backend.tf):

```hcl
terraform {
  backend "gcs" {
    bucket = "gcp-dev-july-2026-terraform-state"
    prefix = "dev/terraform"
  }
}
```

### GCP Service Account

- Store the service account JSON key as a Jenkins **Secret File** credential with ID `gcp-sa-key` (used by every stage in the Jenkinsfile).
- For local runs, a copy of the key is kept at [gcp-sa-key](gcp-sa-key) in the repo root (treat this as sensitive; never commit real production keys).

## Running Terraform Locally (Step by Step)

1. **Clone the repository and change into it**

   ```powershell
   cd D:\gcp-compute-instance
   ```

2. **Point Terraform/gcloud at your service account key** (required so the GCS backend and Google provider can authenticate). In PowerShell this is only set for the current terminal session:

   ```powershell
   $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path .\gcp-sa-key).Path
   ```

3. **Initialize Terraform** (downloads providers, initializes modules, and configures the GCS backend):

   ```powershell
   terraform init
   ```

4. **Validate the configuration**

   ```powershell
   terraform validate
   ```

5. **Review the execution plan**

   ```powershell
   terraform plan -var-file=terraform.tfvars
   ```

6. **Apply the plan** to create the VPC, subnet, firewall, static IP, VM instance, and IAM role bindings:

   ```powershell
   terraform apply -var-file=terraform.tfvars
   ```

7. **View outputs** (instance name, zone, external IP, service account info):

   ```powershell
   terraform output
   ```

8. **Destroy the infrastructure** when no longer needed:

   ```powershell
   terraform destroy -var-file=terraform.tfvars
   ```

> If you see `Error: Backend initialization required` or `could not find default credentials`, re-run step 2 in the current terminal session before retrying `terraform init`.

## Jenkins Pipeline

The pipeline in [Jenkinsfile](Jenkinsfile) is a single parameterized pipeline (no separate IAM/compute-only phases):

### Parameters

- `ACTION` — choice of `apply` or `destroy`
- `TF_WORKING_DIR` — relative path to the Terraform root module (defaults to `.`)
- `VAR_FILE` — Terraform var file to use (defaults to `terraform.tfvars`)

### Stages

1. **Checkout Source Code** — clone the repository from SCM
2. **Authenticate to GCP** — activate the service account from the `gcp-sa-key` Jenkins credential and set the active project
3. **Terraform Format** — `terraform fmt -check -recursive -diff`
4. **Terraform Init** — initialize Terraform with the GCS backend
5. **Terraform Validate** — validate the configuration
6. **Terraform Plan** *(when `ACTION == apply`)* — plan changes and save `tfplan.out`
7. **Manual Approval before Apply** *(when `ACTION == apply`)* — pauses for manual confirmation
8. **Terraform Apply** *(when `ACTION == apply`)* — applies the saved plan
9. **Manual Approval before Destroy** *(when `ACTION == destroy`)* — pauses for manual confirmation
10. **Terraform Destroy** *(when `ACTION == destroy`)* — destroys the managed infrastructure
11. **Display Terraform Outputs** *(on successful apply)* — prints `terraform output`
12. **Workspace Cleanup** — removes the local `.terraform` directory

### Running the Pipeline

1. Create a Pipeline job in Jenkins pointing at this repository's Jenkinsfile.
2. Ensure a Secret File credential with ID `gcp-sa-key` exists (holding the service account JSON key).
3. Trigger a build and choose the `ACTION` parameter (`apply` or `destroy`).
4. Approve the manual gate when prompted to proceed with apply/destroy.

## Outputs

Defined in [outputs.tf](outputs.tf):

- **service_account_email** — Email address of the service account used by the compute instance
- **service_account_name** — Service account ID derived from the email
- **instance_name** — Compute Engine instance name
- **instance_zone** — Zone where the instance is deployed
- **instance_external_ip** — External IP address assigned to the instance
- **service_account_scopes** — OAuth scopes assigned to the instance's service account

## Modules

### `modules/iam`

Assigns each role in `var.required_roles` to the configured service account via `google_project_iam_member`.

### `modules/compute-instance`

Creates:
- A custom VPC network (`google_compute_network`)
- A subnet within that VPC (`google_compute_subnetwork`)
- A firewall rule allowing SSH (`google_compute_firewall`)
- A reserved static external IP (`google_compute_address`)
- The compute instance itself (`google_compute_instance`) with Shielded VM options enabled (secure boot, vTPM, integrity monitoring)

## Terraform Best Practices Followed

- Variables and outputs passed explicitly between root and child modules
- Explicit `depends_on` so IAM roles are applied before the compute instance is created
- No hardcoded values — all configurable values are variables with sensible defaults
- Type specifications and descriptions for all variables
- Remote state stored in GCS for team collaboration and state locking

## Troubleshooting

### `Error: Backend initialization required, please run "terraform init"`

Run `terraform init` after any change to `backend.tf` or module sources.

### `credentials: could not find default credentials`

Set `GOOGLE_APPLICATION_CREDENTIALS` to point at a valid service account key before running any `terraform` command locally:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path .\gcp-sa-key).Path
```

### `Error: Unreadable module directory`

This means `main.tf` references a module `source` path that does not exist on disk (for example a leftover reference to a `modules/validation` directory). Ensure every `module` block in [main.tf](main.tf) points at a directory that actually exists under `modules/`, then re-run `terraform init`.

### API Not Enabled

If you get an error about an API not being enabled, enable it manually:

```bash
gcloud services enable compute.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable cloudresourcemanager.googleapis.com
```

### Service Account Issues

Verify service account permissions:

```bash
gcloud iam service-accounts describe infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com
gcloud projects get-iam-policy gcp-dev-july-2026 --flatten="bindings[].members" --filter="bindings.members:serviceAccount:infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com"
```

### VM Creation Fails

Check Terraform debug logs:

```bash
TF_LOG=DEBUG terraform apply -var-file=terraform.tfvars
```

## Security Considerations

- Service account keys are sensitive — store securely in Jenkins credentials and avoid committing real keys to version control
- Shielded VM features (secure boot, vTPM, integrity monitoring) are enabled on the compute instance
- IAM roles are scoped to what the compute service account needs (see `required_roles` in [variables.tf](variables.tf))
- Terraform state is stored remotely in a GCS bucket rather than locally

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

