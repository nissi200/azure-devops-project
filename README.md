# Automated Deployment of a Web Application using CI/CD, Terraform, Azure, and Jenkins

**Course**: DevOps (24DC2006)  
**Program**: B. Tech AIDS / CO (Semester VII)  
**Institution**: Karunya Institute of Technology and Sciences  

---

## 🚀 Overview

This repository demonstrates a complete end-to-end DevOps CI/CD pipeline that automates:
1. **Infrastructure as Code (IaC)** provisioning on **Microsoft Azure** using **Terraform** (Resource Group, VNet, Subnet, Network Security Group, Network Interface, Public IP, and Ubuntu Virtual Machine).
2. **Continuous Integration (CI)** and **Continuous Deployment (CD)** using **Jenkins** triggered automatically upon GitHub commits.
3. Automated building, testing (Pytest), and deployment of a Python Flask web application on the provisioned Azure VM using systemd and Gunicorn on Port 80.

---

## 🏗️ Architecture & Pipeline Flow

```
[ Developer ] --(git push)--> [ GitHub Repository ]
                                      |
                     (Webhook / Poll SCM Trigger)
                                      v
                             [ Jenkins CI/CD ]
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
  [Stage 1: Checkout]     [Stage 2 & 3: Build & Test]   [Stage 4 & 5: Deploy & Verify]
         |                            |                            |
         v                            v                            v
  Pull latest code          Install dependencies,         SSH & SCP transfer to Azure VM
                            execute Pytest suite         Systemd service reload (Port 80)
                                                                   |
                                                                   v
                                                     [ Azure Ubuntu Virtual Machine ]
                                                     - Resource Group
                                                     - Virtual Network & Subnet
                                                     - Public IP & NSG (22, 80)
```

---

## 📁 Repository Structure

```
azure-devops-project/
├── app/
│   ├── app.py                   # Flask Web Application with health endpoint
│   ├── requirements.txt         # Dependencies (Flask, gunicorn, pytest)
│   ├── deploy.sh                # Automated server deployment script (systemd)
│   ├── templates/
│   │   └── index.html           # Web app dashboard UI
│   └── tests/
│       └── test_app.py          # Pytest automated test suite
├── terraform/
│   ├── provider.tf              # Azure provider declaration
│   ├── variables.tf             # Configurable parameters (VM size, region, etc.)
│   ├── main.tf                  # Azure infrastructure definitions
│   ├── outputs.tf               # Outputs (Public IP, SSH command, Web URL)
│   └── terraform.tfvars.example # Sample variable configurations
├── Jenkinsfile                  # Jenkins Declarative Pipeline (5 stages)
├── .gitignore                   # Ignore keys, tfstate, venv
└── README.md                    # Project documentation
```

---

## 🛠️ Prerequisites & Tools

- **Microsoft Azure Account** (Student Subscription or Free Trial)
- **Azure CLI** (`az`) installed
- **Terraform** (v1.3+) installed
- **Jenkins Server** (running locally, via Docker, or in a separate VM)
- **Git** & **GitHub Account**
- **Python 3.9+**

---

## ⚡ Step-by-Step Implementation Guide

### Step 1: Clone and Configure Repository

```bash
git clone https://github.com/<YOUR_USERNAME>/azure-devops-project.git
cd azure-devops-project
```

### Step 2: Provision Azure Infrastructure with Terraform

1. Authenticate with Azure:
   ```bash
   az login
   ```

2. Navigate to the `terraform/` directory:
   ```bash
   cd terraform
   ```

3. Initialize Terraform plugins:
   ```bash
   terraform init
   ```

4. Validate the configuration and preview changes:
   ```bash
   terraform plan
   ```

5. Apply and provision resources on Azure:
   ```bash
   terraform apply -auto-approve
   ```

6. Note down the outputs:
   - `public_ip_address`: Public IP of the Azure VM
   - `web_application_url`: e.g. `http://20.xx.xx.xx`
   - `azure_vm_key.pem`: SSH private key automatically generated in the `terraform/` folder.

> **Note**: Set secure permissions on your private key:
> ```bash
> chmod 400 azure_vm_key.pem
> ```

---

### Step 3: Configure Jenkins CI/CD

1. **Install Jenkins**:
   - Run Jenkins via Docker:
     ```bash
     docker run -d -p 8080:8080 -p 50000:50000 --name jenkins -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
     ```
   - Or run natively on Ubuntu/Windows.

2. **Install Required Jenkins Plugins**:
   - Go to **Manage Jenkins** > **Plugins** > **Available Plugins**.
   - Install:
     - `SSH Agent Plugin`
     - `Git Plugin`
     - `Pipeline`
     - `JUnit Plugin`

3. **Configure Credentials in Jenkins**:
   - Go to **Manage Jenkins** > **Credentials** > **System** > **Global credentials** > **Add Credentials**:
     - **SSH Key**:
       - Kind: *SSH Username with private key*
       - ID: `azure-vm-ssh-key`
       - Username: `azureuser`
       - Private Key: Paste the content of `terraform/azure_vm_key.pem`
     - **Azure VM IP String**:
       - Kind: *Secret text*
       - ID: `azure-vm-ip`
       - Secret: *Your Azure VM Public IP* (e.g., `20.120.45.67`)

4. **Create Pipeline Job in Jenkins**:
   - Click **New Item** -> Name: `azure-web-pipeline` -> Select **Pipeline** -> OK.
   - Under **Build Triggers**, check **Poll SCM** with schedule: `H/5 * * * *` (or configure GitHub Webhook).
   - Under **Pipeline**, set:
     - Definition: `Pipeline script from SCM`
     - SCM: `Git`
     - Repository URL: `https://github.com/<YOUR_USERNAME>/azure-devops-project.git`
     - Branch: `*/main`
     - Script Path: `Jenkinsfile`
   - Click **Save**.

---

### Step 4: Run the Pipeline & Verify Continuous Deployment

1. Click **Build Now** in Jenkins to trigger the initial pipeline run.
2. Monitor stage execution:
   - `Checkout Source Code` ✅
   - `Build & Prepare Environment` ✅
   - `Run Unit & Quality Tests` ✅
   - `Deploy to Azure VM` ✅
   - `Verification & Health Check` ✅
3. Open your browser and navigate to:
   ```
   http://<YOUR_AZURE_VM_PUBLIC_IP>
   ```
4. Verify Continuous Deployment:
   - Edit `app/templates/index.html` (e.g. change version banner or title).
   - Commit and push to GitHub:
     ```bash
     git add .
     git commit -m "feat: updated landing page banner"
     git push origin main
     ```
   - Watch Jenkins automatically detect the commit, trigger the build, and redeploy to Azure without manual intervention!

---

### Step 5: Clean Up Azure Resources (After Demo/Submission)

To avoid Azure cloud charges after completing your evaluation:
```bash
cd terraform
terraform destroy -auto-approve
```
