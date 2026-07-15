pipeline {
  agent any

  parameters {
    booleanParam(name: 'DESTROY', defaultValue: false, description: 'Run terraform destroy instead of apply')
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
    buildDiscarder(logRotator(numToKeepStr: '5'))
  }

  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        checkout scm
      }
    }

    stage('Authenticate to GCP') {
      steps {
        withCredentials([
            file(
                credentialsId: 'gcp-sa-key',
                variable: 'GOOGLE_APPLICATION_CREDENTIALS'
            )
        ]) {
            sh '''
                set -e

                export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
                mkdir -p "$CLOUDSDK_CONFIG"

                echo "Activating GCP Service Account..."
                gcloud auth activate-service-account \
                  --key-file="$GOOGLE_APPLICATION_CREDENTIALS"

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

    stage('Ensure Backend Bucket Access') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e

            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"

            ACTIVE_SA="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"
            if [ -z "$ACTIVE_SA" ]; then
              echo "ERROR: No active service account found after authentication"
              exit 1
            fi

            if ! gcloud storage buckets describe "gs://$BACKEND_BUCKET" >/dev/null 2>&1; then
              echo "Backend bucket not accessible; attempting to create gs://$BACKEND_BUCKET in $PROJECT_ID"
              gcloud storage buckets create "gs://$BACKEND_BUCKET" \
                --project="$PROJECT_ID" \
                --location="US" \
                --uniform-bucket-level-access
            fi

            # Ensure Terraform runner can list/read/write state objects.
            gcloud storage buckets add-iam-policy-binding "gs://$BACKEND_BUCKET" \
              --member="serviceAccount:$ACTIVE_SA" \
              --role="roles/storage.objectAdmin" \
              --quiet
          '''
        }
      }
    }

    stage('Terraform Init') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e

            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"

            ACCESS_TOKEN="$(gcloud auth print-access-token)"
            export GOOGLE_OAUTH_ACCESS_TOKEN="$ACCESS_TOKEN"

            terraform init \
              -reconfigure \
              -backend-config="access_token=$ACCESS_TOKEN" \
              -backend-config="bucket=$BACKEND_BUCKET" \
              -backend-config="prefix=${ENVIRONMENT}/terraform"
          '''
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"
            export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
            terraform validate
          '''
        }
      }
    }

    stage('Terraform Plan') {
      when {
        expression { return params.DESTROY == false }
      }
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"
            export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
            rm -f tfplan
            terraform plan -var-file=terraform.tfvars -out=tfplan
          '''
        }
      }
    }

    stage('Terraform Apply') {
      when {
        expression { return params.DESTROY == false }
      }
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"
            export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
            terraform apply -auto-approve tfplan
          '''
        }
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { return params.DESTROY == true }
      }
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e
            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"
            export GOOGLE_OAUTH_ACCESS_TOKEN="$(gcloud auth print-access-token)"
            terraform destroy -var-file=terraform.tfvars -auto-approve
          '''
        }
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
