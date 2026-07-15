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

    stage('Verify Backend Bucket Access') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e

            export CLOUDSDK_CONFIG="$WORKSPACE/.gcloud"
            mkdir -p "$CLOUDSDK_CONFIG"
            gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
            gcloud config set project "$PROJECT_ID"

            echo "Verifying access to existing backend bucket gs://$BACKEND_BUCKET ..."
            if ! gcloud storage buckets describe "gs://$BACKEND_BUCKET" >/dev/null 2>&1; then
              echo "ERROR: Cannot access gs://$BACKEND_BUCKET. Ensure the bucket already exists and the service account has the required storage IAM roles (e.g. roles/storage.objectAdmin)."
              exit 1
            fi

            echo "Backend bucket is accessible."
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