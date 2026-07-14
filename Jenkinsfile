pipeline {
  agent any

  environment {
    TF_IN_AUTOMATION = 'true'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Terraform Version') {
      steps {
        sh 'terraform version'
      }
    }

    stage('Terraform Format') {
      steps {
        sh 'terraform fmt -check -recursive'
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

    stage('Outputs') {
      steps {
        sh 'terraform output'
      }
    }
  }

  post {
    always {
      echo 'Workspace cleanup complete.'
      sh 'rm -f tfplan'
    }
    failure {
      echo 'Pipeline failed. Review the logs for details.'
    }
  }
}
