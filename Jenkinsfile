pipeline {
  agent any

  environment {
    GOOGLE_APPLICATION_CREDENTIALS = '/var/jenkins_home/gcp-sa-key.json'
    TF_IN_AUTOMATION               = 'true'
    TF_INPUT                       = 'false'
    TF_LOG                         = 'INFO'
    PROJECT_ID                     = 'gcp-dev-july-2026'
    REGION                         = 'us-central1'
    ZONE                           = 'us-central1-a'
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

    stage('Terraform Format') {
      steps {
        sh 'terraform fmt -recursive -check'
      }
    }

    stage('Terraform Init') {
      steps {
        sh 'terraform init'
      }
    }

    stage('Terraform Validate') {
      steps {
        sh 'terraform validate'
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -var-file=dev.tfvars -out=tfplan'
      }
    }

    stage('Manual Approval') {
      steps {
        input message: 'Approve Terraform apply?'
      }
    }

    stage('Terraform Apply') {
      steps {
        sh 'terraform apply -auto-approve tfplan'
      }
    }

    stage('Terraform Output') {
      steps {
        sh 'terraform output'
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
