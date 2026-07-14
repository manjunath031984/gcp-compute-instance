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

    stage('Verify Tools') {
      steps {
        sh '''
          echo "terraform version"
          terraform version
          echo "gcloud version"
          gcloud version
          echo "git version"
          git --version
          echo "docker version"
          if command -v docker >/dev/null 2>&1; then
            docker --version
          else
            echo "docker is not installed in this agent"
          fi
          echo "python3 version"
          if command -v python3 >/dev/null 2>&1; then
            python3 --version
          else
            echo "python3 is not installed in this agent"
          fi
        '''
      }
    }

    stage('Verify Credentials') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh '''
            echo "Using credentials file: $GOOGLE_APPLICATION_CREDENTIALS"
            ls -l "$GOOGLE_APPLICATION_CREDENTIALS"
          '''
        }
      }
    }

    stage('Prepare GCP Service Account') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          script {
            env.SERVICE_ACCOUNT_EMAIL = "gcp-compute-instance@${env.PROJECT_ID}.iam.gserviceaccount.com"
            def exists = sh(script: '''
              set -e
              gcloud auth activate-service-account --key-file="$GOOGLE_APPLICATION_CREDENTIALS"
              if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
                echo true
              else
                echo false
              fi
            ''', returnStdout: true).trim()
            env.USE_EXISTING_SERVICE_ACCOUNT = exists
            echo "Using existing service account: ${exists}"
          }
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
          sh 'terraform init -backend-config="credentials=$GOOGLE_APPLICATION_CREDENTIALS"'
        }
      }
    }

    stage('Terraform Validate') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'terraform validate -var="use_existing_service_account=${USE_EXISTING_SERVICE_ACCOUNT}"'
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'terraform plan -var-file=dev.tfvars -var="use_existing_service_account=${USE_EXISTING_SERVICE_ACCOUNT}" -out=tfplan'
        }
      }
    }

    stage('Manual Approval') {
      steps {
        input message: 'Approve Terraform apply?'
      }
    }

    stage('Terraform Apply') {
      steps {
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'terraform apply -auto-approve tfplan'
        }
      }
    }

    stage('Terraform Output') {
      steps {
        sh 'terraform output'
      }
    }

    stage('Terraform Destroy') {
      when {
        expression { return params.DESTROY == true }
      }
      steps {
        input message: 'Confirm Terraform destroy?'
        withCredentials([file(credentialsId: 'gcp-sa-key', variable: 'GOOGLE_APPLICATION_CREDENTIALS')]) {
          sh 'terraform destroy -var-file=dev.tfvars -auto-approve'
        }
      }
    }

    stage('Workspace Cleanup') {
      steps {
        sh 'rm -f tfplan'
      }
    }
  }

  post {
    always {
      cleanWs()
    }
    success {
      echo 'Deployment Successful'
    }
    failure {
      echo 'Deployment Failed'
    }
  }
}
