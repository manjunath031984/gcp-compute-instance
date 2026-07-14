pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Run Terraform destroy after apply')
    booleanParam(name: 'ROTATE_GCP_CREDENTIAL', defaultValue: false, description: 'Rotate the GCP service account key and update the Jenkins file credential before deployment')
    string(name: 'GCP_SA_CREDENTIAL_ID', defaultValue: 'gcp-service-account-key', description: 'Jenkins Secret File credential ID for the GCP service account JSON key')
    string(name: 'JENKINS_API_CREDENTIAL_ID', defaultValue: 'jenkins-api-user', description: 'Jenkins username/password credential ID used only when rotating the GCP credential')
    string(name: 'JENKINS_URL_CREDENTIAL_ID', defaultValue: 'jenkins-url', description: 'Jenkins string credential ID for the base Jenkins URL used only when rotating the GCP credential')
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

    stage('Setup GCP Authentication') {
      when {
        expression { return params.ROTATE_GCP_CREDENTIAL == true }
      }
      steps {
        withCredentials([
          usernamePassword(credentialsId: params.JENKINS_API_CREDENTIAL_ID, usernameVariable: 'JENKINS_USERNAME', passwordVariable: 'JENKINS_API_TOKEN'),
          string(credentialsId: params.JENKINS_URL_CREDENTIAL_ID, variable: 'JENKINS_URL')
        ]) {
          sh '''
            set -e
            chmod +x scripts/setup-gcp-service-account.sh
            export GOOGLE_CLOUD_PROJECT="$PROJECT_ID"
            scripts/setup-gcp-service-account.sh
          '''
        }
      }
    }

       stage('Authenticate to GCP') {
      steps {
        withCredentials([file(credentialsId: params.GCP_SA_CREDENTIAL_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
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
        withCredentials([file(credentialsId: params.GCP_SA_CREDENTIAL_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
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
