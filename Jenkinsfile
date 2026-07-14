pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Run terraform destroy instead of apply')
    string(name: 'GCP_SA_CREDENTIAL_ID', defaultValue: 'gcp-sa-key', description: 'Jenkins Secret File credential ID for the existing GCP service account key')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
    PROJECT_ID       = 'gcp-dev-july-2026'
    ENVIRONMENT      = 'dev'
    BACKEND_BUCKET   = 'gcp-dev-july-2026-terraform-state'
  }

  options {
    disableConcurrentBuilds()
    timestamps()
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Authenticate to GCP') {
    steps {
        withCredentials([
            file(
                credentialsId: params.GCP_SA_CREDENTIAL_ID,
                variable: 'GOOGLE_APPLICATION_CREDENTIALS'
            )
        ]) {
            sh '''
                set -e

                export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
                mkdir -p "$CLOUDSDK_CONFIG"

            python3 - <<'PY'
    import json
    import os

    key_path = os.environ['GOOGLE_APPLICATION_CREDENTIALS']
    with open(key_path, 'r', encoding='utf-8') as key_file:
      key = json.load(key_file)

    required = ['type', 'private_key_id', 'private_key', 'client_email', 'token_uri']
    missing = [name for name in required if not key.get(name)]
    if missing:
      raise SystemExit('Jenkins credential is missing required JSON key fields: ' + ', '.join(missing))

    if key['type'] != 'service_account':
      raise SystemExit('Jenkins credential is not a service account JSON key file.')

    print('Credential metadata:')
    print('  client_email = ' + key['client_email'])
    print('  private_key_id = ' + key['private_key_id'])
    PY

                echo "Activating GCP Service Account..."
            if ! gcloud auth activate-service-account \
              --key-file="$GOOGLE_APPLICATION_CREDENTIALS"; then
              echo "GCP authentication failed. The Jenkins Secret File credential '$GCP_SA_CREDENTIAL_ID' is likely stale, revoked, or uploaded with corrupted JSON/key material."
              echo "Re-upload a fresh JSON key for infra-admin@gcp-dev-july-2026.iam.gserviceaccount.com to Jenkins and rerun the job."
              exit 1
            fi

                echo "Setting GCP Project..."
                gcloud config set project "$PROJECT_ID"

                echo "Authenticated Accounts:"
                gcloud auth list

                echo "Current Project:"
                gcloud config get-value project
            '''
        }
    }
}

    stage('Terraform Init') {
      steps {
        withCredentials([file(credentialsId: params.GCP_SA_CREDENTIAL_ID, variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            terraform init \
              -backend-config="bucket=$BACKEND_BUCKET" \
              -backend-config="prefix=${ENVIRONMENT}/terraform" \
              -backend-config="credentials=$GOOGLE_APPLICATION_CREDENTIALS"
          '''
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        sh 'terraform validate'
      }
    }

    stage('Terraform Plan') {
      when {
        expression { return params.DESTROY == false }
      }
      steps {
        sh 'terraform plan -var-file=terraform.tfvars -out=tfplan'
      }
    }

    stage('Terraform Apply') {
      when {
        expression { return params.DESTROY == false }
      }
      steps {
        sh 'terraform apply -auto-approve tfplan'
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { return params.DESTROY == true }
      }
      steps {
        sh 'terraform destroy -var-file=terraform.tfvars -auto-approve'
      }
    }
  }

  post {
    always {
      sh 'rm -f tfplan'
      cleanWs()
    }
  }
}
