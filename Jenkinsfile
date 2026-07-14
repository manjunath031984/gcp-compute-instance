pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Run Terraform destroy after apply')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
    TF_LOG           = 'INFO'
    PROJECT_ID       = 'gcp-dev-july-2026'
    REGION           = 'us-central1'
    ZONE             = 'us-central1-a'
    ENVIRONMENT      = 'dev'
    BACKEND_BUCKET   = 'gcp-dev-july-2026-terraform-state'
  }

  options {
    disableConcurrentBuilds()
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Agent TLS Preflight') {
      steps {
        sh '''
          set -e
          export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
          mkdir -p "$CLOUDSDK_CONFIG"

          if ! command -v gcloud >/dev/null 2>&1; then
            echo "ERROR: gcloud CLI is not installed on this Jenkins agent"
            exit 1
          fi

          gcloud --version

          if command -v python3 >/dev/null 2>&1; then
            export CLOUDSDK_PYTHON="$(command -v python3)"
            python3 - <<'PY'
import ssl
v = ssl.OPENSSL_VERSION_INFO
print("Python OpenSSL:", ssl.OPENSSL_VERSION)
if v < (1, 1, 1):
    raise SystemExit("OpenSSL is too old. Require >= 1.1.1 for modern Google OAuth TLS")
PY
          else
            echo "WARNING: python3 not found. gcloud may use an older Python runtime."
          fi

          if command -v curl >/dev/null 2>&1; then
            curl --silent --show-error --fail --tlsv1.2 https://oauth2.googleapis.com/.well-known/openid-configuration >/dev/null
          elif command -v python3 >/dev/null 2>&1; then
            python3 - <<'PY'
import urllib.request
urllib.request.urlopen("https://oauth2.googleapis.com/.well-known/openid-configuration", timeout=20)
print("OAuth endpoint TLS check passed")
PY
          else
            echo "ERROR: Neither curl nor python3 is available for TLS preflight checks"
            exit 1
          fi
        '''
      }
    }

    stage('Authenticate to GCP') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            if command -v python3 >/dev/null 2>&1; then
              export CLOUDSDK_PYTHON="$(command -v python3)"
            fi
            export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud auth revoke --all --quiet || true
            gcloud --version
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"
            gcloud auth list
            gcloud config list
          '''
        }
      }
    }

    stage('Terraform Format') {
      steps {
        sh 'terraform fmt -recursive -check'
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'terraform init -backend-config="bucket=$BACKEND_BUCKET" -backend-config="prefix=${ENVIRONMENT}/terraform" -backend-config="credentials=$GOOGLE_APPLICATION_CREDENTIALS"'
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        sh 'terraform validate'
      }
    }

    stage('Terraform Plan (IAM)') {
      steps {
        sh 'terraform plan -var-file=terraform.tfvars -out=iam.plan -target=module.service_account -target=module.iam'
      }
    }

    stage('Terraform Apply (IAM)') {
      steps {
        sh 'terraform apply -auto-approve iam.plan'
      }
    }

    stage('IAM Validation') {
      steps {
        sh '''
          set -e
          export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
          mkdir -p "$CLOUDSDK_CONFIG"
          if command -v python3 >/dev/null 2>&1; then
            export CLOUDSDK_PYTHON="$(command -v python3)"
          fi
          SERVICE_ACCOUNT_EMAIL=$(terraform output -raw service_account_email)
          terraform output -raw service_account_key > generated-service-account.json
          export GOOGLE_APPLICATION_CREDENTIALS="$PWD/generated-service-account.json"
          gcloud auth revoke --all --quiet || true
          gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
          gcloud config set project "$PROJECT_ID"
          gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID"
          for role in \
            roles/compute.admin \
            roles/compute.instanceAdmin.v1 \
            roles/iam.serviceAccountUser \
            roles/iam.serviceAccountTokenCreator \
            roles/storage.admin \
            roles/storage.objectAdmin \
            roles/logging.logWriter \
            roles/monitoring.metricWriter \
            roles/compute.networkAdmin \
            roles/compute.securityAdmin \
            roles/serviceusage.serviceUsageAdmin; do
            if ! gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[]" --filter="bindings.members:serviceAccount:$SERVICE_ACCOUNT_EMAIL" --format="value(bindings.role)" | grep -qx "$role"; then
              echo "ERROR: Required role $role is not attached to the service account"
              exit 1
            fi
          done
        '''
      }
    }

    stage('Manual Approval') {
      steps {
        input message: 'Approve compute instance creation?'
      }
    }

    stage('Terraform Plan (Compute)') {
      steps {
        sh 'terraform plan -var-file=terraform.tfvars -out=compute.plan'
      }
    }

    stage('Terraform Apply (Compute)') {
      steps {
        sh 'terraform apply -auto-approve compute.plan'
      }
    }

    stage('VM Verification') {
      steps {
        sh '''
          set -e
          export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
          mkdir -p "$CLOUDSDK_CONFIG"
          if command -v python3 >/dev/null 2>&1; then
            export CLOUDSDK_PYTHON="$(command -v python3)"
          fi
          INSTANCE_NAME=$(terraform output -raw instance_name)
          ZONE=$(terraform output -raw instance_zone)
          SERVICE_ACCOUNT_EMAIL=$(terraform output -raw service_account_email)
          EXTERNAL_IP=$(terraform output -raw instance_external_ip)
          if ! gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
            echo "ERROR: VM $INSTANCE_NAME does not exist"
            exit 1
          fi
          STATUS=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --format='value(status)')
          if [ "$STATUS" != "RUNNING" ]; then
            echo "ERROR: VM status is $STATUS"
            exit 1
          fi
          ACTUAL_SA=$(gcloud compute instances describe "$INSTANCE_NAME" --zone="$ZONE" --project="$PROJECT_ID" --format='value(serviceAccounts.email)')
          if [ "$ACTUAL_SA" != "$SERVICE_ACCOUNT_EMAIL" ]; then
            echo "ERROR: Service account mismatch: expected $SERVICE_ACCOUNT_EMAIL got $ACTUAL_SA"
            exit 1
          fi
          if [ -z "$EXTERNAL_IP" ]; then
            echo "ERROR: External IP is missing"
            exit 1
          fi
          echo "VM verification complete: $INSTANCE_NAME is RUNNING with external IP $EXTERNAL_IP"
        '''
      }
    }

    stage('Terraform Outputs') {
      steps {
        sh 'terraform output'
      }
    }

    stage('Cleanup') {
      steps {
        sh 'rm -f iam.plan compute.plan'
      }
    }

    stage('Destroy') {
      when {
        expression { return params.DESTROY == true }
      }
      steps {
        input message: 'Confirm destroy?'
        sh 'terraform destroy -var-file=terraform.tfvars -auto-approve'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo 'Deployment completed successfully.'
    }
    failure {
      echo 'Deployment failed.'
    }
  }
}
