pipeline {
    agent any

    triggers {
        // Automatically poll GitHub every 5 minutes for changes (ideal for local/NAT Jenkins)
        pollSCM('H/5 * * * *')
    }

    environment {
        // Set your Azure VM Public IP address obtained from 'terraform output'
        AZURE_VM_IP        = credentials('azure-vm-ip') // Or hardcode: '20.xx.xx.xx'
        AZURE_USER         = 'azureuser'
        SSH_CREDENTIAL_ID  = 'azure-vm-ssh-key' // Jenkins SSH Username with private key credential ID
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                echo '=== Stage 1: Checking out source code from GitHub ==='
                checkout scm
            }
        }

        stage('Build & Prepare Environment') {
            steps {
                echo '=== Stage 2: Installing dependencies and building app ==='
                dir('app') {
                    sh '''
                        python3 -m venv venv || python -m venv venv
                        . venv/bin/activate || . venv/Scripts/activate
                        pip install --upgrade pip
                        pip install -r requirements.txt
                    '''
                }
            }
        }

        stage('Run Unit & Quality Tests') {
            steps {
                echo '=== Stage 3: Running Automated Pytest Suite ==='
                dir('app') {
                    sh '''
                        . venv/bin/activate || . venv/Scripts/activate
                        pytest tests/test_app.py -v --junitxml=test-results.xml
                    '''
                }
            }
            post {
                always {
                    junit allowEmptyResults: true, testResults: 'app/test-results.xml'
                }
            }
        }

        stage('Deploy to Azure VM') {
            steps {
                echo "=== Stage 4: Deploying Application to Azure VM at ${AZURE_VM_IP} ==="
                sshagent([env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        # Prevent strict host key checking prompt during automated CI
                        SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
                        
                        echo "Transferring app files to Azure VM..."
                        scp ${SSH_OPTS} -r app/* ${AZURE_USER}@${AZURE_VM_IP}:/home/${AZURE_USER}/devops-deploy/
                        
                        echo "Executing remote deployment script..."
                        ssh ${SSH_OPTS} ${AZURE_USER}@${AZURE_VM_IP} << 'EOF'
                            mkdir -p ~/devops-deploy
                            cd ~/devops-deploy
                            chmod +x deploy.sh
                            ./deploy.sh
EOF
                    '''
                }
            }
        }

        stage('Verification & Health Check') {
            steps {
                echo '=== Stage 5: Verifying Live Web App on Azure ==='
                sh '''
                    echo "Checking live web application endpoint..."
                    sleep 5
                    curl --retry 5 --retry-delay 3 -f http://${AZURE_VM_IP}/health || {
                        echo "Health check failed!"
                        exit 1
                    }
                    echo "Application is LIVE and responding at: http://${AZURE_VM_IP}"
                '''
            }
        }
    }

    post {
        success {
            echo "=========================================================="
            echo "CI/CD Pipeline Succeeded!"
            echo "Application is live at: http://${AZURE_VM_IP}"
            echo "=========================================================="
        }
        failure {
            echo "Pipeline failed! Please inspect logs above for details."
        }
    }
}
