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
          docker --version
          echo "python3 version"
          python3 --version
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
