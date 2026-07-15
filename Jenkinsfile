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

    stage('Terraform Init') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            set -e

            # Use JSON content for backend auth to avoid temp file path resolution issues.
            [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]
            export GOOGLE_BACKEND_CREDENTIALS="$(cat "$GOOGLE_APPLICATION_CREDENTIALS")"
            export GOOGLE_CREDENTIALS="$GOOGLE_BACKEND_CREDENTIALS"

            terraform init \
              -reconfigure \
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
            export GOOGLE_BACKEND_CREDENTIALS="$(cat "$GOOGLE_APPLICATION_CREDENTIALS")"
            export GOOGLE_CREDENTIALS="$GOOGLE_BACKEND_CREDENTIALS"
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
            export GOOGLE_BACKEND_CREDENTIALS="$(cat "$GOOGLE_APPLICATION_CREDENTIALS")"
            export GOOGLE_CREDENTIALS="$GOOGLE_BACKEND_CREDENTIALS"
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
            export GOOGLE_BACKEND_CREDENTIALS="$(cat "$GOOGLE_APPLICATION_CREDENTIALS")"
            export GOOGLE_CREDENTIALS="$GOOGLE_BACKEND_CREDENTIALS"
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
            export GOOGLE_BACKEND_CREDENTIALS="$(cat "$GOOGLE_APPLICATION_CREDENTIALS")"
            export GOOGLE_CREDENTIALS="$GOOGLE_BACKEND_CREDENTIALS"
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
