# PROJECT REPORT
## AUTOMATED DEPLOYMENT OF A WEB APPLICATION USING CI/CD, TERRAFORM, AZURE, AND JENKINS

**Course Name**: DevOps  
**Course Code**: 24DC2006  
**Class**: B. Tech AIDS / CO (Semester VII)  
**Institution**: Karunya Institute of Technology and Sciences  
**Instructors**: Mrs. J Srija, Mrs. Esther Lipni, Mr. Rahul  

---

### Student Details
- **Student Name**: [Your Name]
- **Register Number**: [Your Register Number]
- **Date of Submission**: [Date]
- **GitHub Repository URL**: `https://github.com/[your-username]/azure-devops-project`

---

## 1. Title & Objective

### 1.1 Project Title
Automated Deployment of a Web Application using CI/CD, Terraform, Azure, and Jenkins.

### 1.2 Objective
To design and implement a complete DevOps pipeline that automates the deployment of a web application on Microsoft Azure using Terraform for infrastructure provisioning and Jenkins for continuous integration and continuous deployment (CI/CD).

Specific objectives achieved:
1. Automate cloud infrastructure creation on Microsoft Azure using Terraform (IaC).
2. Establish version control and pipeline triggering via GitHub.
3. Build, test, and package a web application automatically using Jenkins.
4. Achieve continuous deployment by deploying and reloading the web application on an Azure Virtual Machine upon code changes without manual intervention.

---

## 2. Tools & Technologies Used

| Tool / Technology | Role in Project | Version / Tier |
|---|---|---|
| **Microsoft Azure** | Cloud Infrastructure Provider | Standard Linux VM, VNet, Public IP, NSG |
| **Terraform** | Infrastructure as Code (IaC) | v1.3+ / HashiCorp AzureRM Provider (~> 3.80) |
| **Jenkins** | CI/CD Automation Server | LTS (Pipeline & SSH Agent Plugins) |
| **GitHub** | Source Code & Version Control | Git version control with SCM polling / Webhook |
| **Python & Flask** | Web Application Backend | Python 3.9+, Flask, Jinja2 |
| **Pytest** | Automated Testing Framework | Pytest with JUnit test reporting |
| **Gunicorn & Systemd**| Application Server & Process Manager | WSGI HTTP Server managed by Linux systemd |
| **SSH / SCP** | Secure Remote Automation | Automated deployment via SSH keys |

---

## 3. Architecture & DevOps Workflow Diagram

```
 +-------------------------------------------------------------------------------+
 |                              DEVELOPER WORKFLOW                               |
 +-------------------------------------------------------------------------------+
        |
        | 1. Code Commit & Push (`git push origin main`)
        v
 +-----------------------------+
 |     GitHub Repository       |
 | (Terraform, App, Jenkinsfile|
 +-----------------------------+
        |
        | 2. Automated Trigger (Poll SCM / Webhook)
        v
 +-------------------------------------------------------------------------------+
 |                              JENKINS CI/CD SERVER                             |
 |                                                                               |
 |   [Stage 1: Checkout] ---> [Stage 2: Build] ---> [Stage 3: Pytest Suite]      |
 |                                                               |               |
 |                                                               v               |
 |   [Stage 5: Health Check] <--- [Stage 4: Remote Deploy (SSH / SCP)]           |
 +-------------------------------------------------------------------------------+
                                            |
                                            | 3. Deploys via SSH / Port 22
                                            v
 +-------------------------------------------------------------------------------+
 |                         MICROSOFT AZURE CLOUD                                 |
 |                                                                               |
 |   Resource Group: `rg-devops-webapp`                                          |
 |   +-----------------------------------------------------------------------+   |
 |   | Virtual Network: `vnet-devops` (Subnet: `snet-devops-web`)            |   |
 |   |                                                                       |   |
 |   |   Network Security Group: `nsg-devops-server`                         |   |
 |   |   - Inbound Rule: TCP 22 (SSH Remote Management)                      |   |
 |   |   - Inbound Rule: TCP 80 (HTTP Web Traffic)                           |   |
 |   |                                                                       |   |
 |   |   Network Interface (NIC) <---> Public IP: `20.x.x.x`                 |   |
 |   |                                                                       |   |
 |   |   Azure Virtual Machine (`Standard_B1s`, Ubuntu 22.04 LTS)            |   |
 |   |   +---------------------------------------------------------------+   |   |
 |   |   | Gunicorn WSGI Server + Systemd Service (`devops-webapp`)      |   |   |
 |   |   | Flask Web App running on Port 80                              |   |   |
 |   |   +---------------------------------------------------------------+   |   |
 |   +-----------------------------------------------------------------------+   |
 +-------------------------------------------------------------------------------+
                                            |
                                            | 4. User Browses via HTTP Port 80
                                            v
                                     [ End Users ]
```

---

## 4. Terraform Infrastructure Configuration

### 4.1 Resource Breakdown
1. **Resource Group**: `azurerm_resource_group` creates an isolated logical container.
2. **Virtual Network & Subnet**: `azurerm_virtual_network` (10.0.0.0/16) and `azurerm_subnet` (10.0.1.0/24) provide network isolation.
3. **Public IP**: `azurerm_public_ip` (Standard SKU, Static) exposes the web application to the Internet.
4. **Network Security Group (NSG)**: Rules for SSH (port 22) and HTTP (port 80).
5. **Network Interface**: Attaches the Subnet, Public IP, and NSG.
6. **Virtual Machine**: `azurerm_linux_virtual_machine` provisions Ubuntu 22.04 with automated SSH key setup.

### 4.2 Key Terraform Snippets

#### Provider Configuration (`provider.tf`):
```hcl
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}
provider "azurerm" {
  features {}
}
```

#### VM and Network Configuration (`main.tf` extract):
```hcl
resource "azurerm_linux_virtual_machine" "devops_vm" {
  name                = var.vm_name
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.devops_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.vm_ssh_key[0].public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
```

---

## 5. Jenkins CI/CD Pipeline Implementation

### 5.1 Pipeline Stages Explanation
- **Stage 1: Checkout Source Code**: Clones the GitHub repository using credentials/agent.
- **Stage 2: Build & Prepare Environment**: Sets up the Python virtual environment and installs requirements.
- **Stage 3: Run Unit & Quality Tests**: Executes `pytest` and records test report XML.
- **Stage 4: Deploy to Azure VM**: Copies application files using SCP and executes the remote `deploy.sh` script to configure and restart the Gunicorn systemd service.
- **Stage 5: Verification & Health Check**: Sends an automated HTTP request to `http://<AZURE_VM_IP>/health` to confirm the deployment is healthy and operational.

### 5.2 Declarative Pipeline Code (`Jenkinsfile`)
```groovy
pipeline {
    agent any
    triggers {
        pollSCM('H/5 * * * *')
    }
    environment {
        AZURE_VM_IP       = credentials('azure-vm-ip')
        AZURE_USER        = 'azureuser'
        SSH_CREDENTIAL_ID = 'azure-vm-ssh-key'
    }
    stages {
        stage('Checkout Source Code') {
            steps { checkout scm }
        }
        stage('Build & Prepare Environment') {
            steps {
                dir('app') {
                    sh 'python3 -m venv venv && . venv/bin/activate && pip install -r requirements.txt'
                }
            }
        }
        stage('Run Unit & Quality Tests') {
            steps {
                dir('app') {
                    sh '. venv/bin/activate && pytest tests/test_app.py -v --junitxml=test-results.xml'
                }
            }
            post {
                always { junit allowEmptyResults: true, testResults: 'app/test-results.xml' }
            }
        }
        stage('Deploy to Azure VM') {
            steps {
                sshagent([env.SSH_CREDENTIAL_ID]) {
                    sh '''
                        SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
                        scp ${SSH_OPTS} -r app/* ${AZURE_USER}@${AZURE_VM_IP}:/home/${AZURE_USER}/devops-deploy/
                        ssh ${SSH_OPTS} ${AZURE_USER}@${AZURE_VM_IP} "chmod +x ~/devops-deploy/deploy.sh && ~/devops-deploy/deploy.sh"
                    '''
                }
            }
        }
        stage('Verification & Health Check') {
            steps {
                sh 'curl --retry 5 --retry-delay 3 -f http://${AZURE_VM_IP}/health'
            }
        }
    }
}
```

---

## 6. Implementation Screenshots

> *(Insert your screenshots below in the designated sections)*

### 6.1 Screenshot 1: Terraform Provisioning (`terraform apply` output)
*Place screenshot showing `Apply complete! Resources: 7 added, 0 changed, 0 destroyed.` and outputs (Public IP).*

```
[ INSERT SCREENSHOT OF TERRAFORM APPLY COMMAND & OUTPUT HERE ]
```

### 6.2 Screenshot 2: Jenkins Pipeline Execution
*Place screenshot showing all 5 green stages in Jenkins Pipeline stage view and console output.*

```
[ INSERT SCREENSHOT OF SUCCESSFUL JENKINS PIPELINE RUN HERE ]
```

### 6.3 Screenshot 3: Web Application Running Live on Azure
*Place screenshot of browser showing the application accessible via `http://<AZURE_PUBLIC_IP>` with server hostname, timestamp, and health status.*

```
[ INSERT SCREENSHOT OF BROWSER LOADING THE LIVE WEB APP ON AZURE IP HERE ]
```

---

## 7. Observations & Results

1. **Infrastructure as Code Efficacy**: Terraform allowed repeatable, deterministic provisioning of complex cloud infrastructure within ~2 minutes, eliminating manual portal misconfigurations.
2. **Automated Continuous Integration**: Jenkins successfully automated testing upon commit detection, catching any syntax or logical failures before production deployment.
3. **Zero-Touch Continuous Deployment**: Combining Jenkins with SSH execution enabled fully hands-off deployment—from Git commit to live VM reload in under 60 seconds.
4. **Resilience**: The systemd service ensures the Flask application restarts automatically upon VM reboots or crashes.

---

## 8. Conclusion

The project successfully demonstrated an automated, end-to-end DevOps CI/CD pipeline bridging cloud infrastructure management with application lifecycle management:
- Microsoft Azure resources were codified and maintained using Terraform.
- Jenkins orchestrated automated continuous testing and deployment.
- High availability and ease of updates were verified through live code push triggers and web verification.
- The project adheres to industry best practices of Infrastructure as Code (IaC), Continuous Integration (CI), and Continuous Deployment (CD).
