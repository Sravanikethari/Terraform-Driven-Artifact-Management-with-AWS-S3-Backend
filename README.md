# DevSecOps CI/CD Pipeline with GitOps on Kubernetes
## Project Overview

Built a cloud-native CI/CD pipeline for a Java application using Jenkins, Docker, Kubernetes, and Terraform on AWS, automating the entire delivery lifecycle from code commit to deployment. Containerization and Kubernetes-based deployment reduced manual deployment effort by ~70%, improved reliability through self-healing and rolling updates, and ensured consistent environments. Integrated SonarQube, OWASP Dependency-Check, and Trivy to enforce automated quality and security checks before deployment.

## Introduction

This project showcases a cloud-native CI/CD pipeline for a Java application using Jenkins, Docker, Kubernetes, and Terraform on AWS. The pipeline automates build, testing, security scanning, containerization, and deployment, while Kubernetes enables scalable, self-healing deployments and Terraform ensures reproducible infrastructure. Integrated quality and security checks ensure reliable, production-ready releases.


## Architecture Overview

    - Infrastructure provisioned using Terraform with AWS S3 remote backend
    - Kubernetes cluster used for application deployment
    - Application packaged as Docker image
    - Kubernetes Deployment manages replicas
    - Kubernetes Service exposes the application


## Technologies Used

    1.	Maven – Application development and build management tool. Compiles code, runs tests, manages dependencies, and packages the Java application into a .war file.

   
    2.	Jenkins – CI/CD orchestration engine running on AWS EC2. Automatically triggers on GitHub push, executes the full pipeline, and provides complete visibility and control.

	
    3.	GitHub – Source code repository and version control system. Hosts the application code, Jenkinsfile, Dockerfile, and Terraform scripts while instantly triggering Jenkins via webhook.

	
    4.	SonarQube (via Docker) – Static code analysis platform. Detects bugs, code smells, security vulnerabilities, duplication, and enforces quality gates before deployment.

	
    5.	OWASP Dependency-Check – Dependency vulnerability scanner. Checks all libraries in pom.xml against known vulnerability databases and fails the build on critical issues.

	
    6.	Docker – Containerization platform. Builds lightweight, consistent images of the application for reproducible environments (optional deployment path).

    7.	Trivy – Container image security scanner. Quickly identifies OS and application-level vulnerabilities in Docker images before pushing to registry.

    8.  Kubernetes (kOps) – Container orchestration platform. Manages containerized application deployment, scaling, self-healing, and service exposure using Deployments and Services, enabling high availability and production-ready workloads.
   
    9. Argo CD – GitOps continuous delivery tool. Automatically synchronizes Kubernetes manifests from Git repositories to the cluster, ensuring the desired application state and eliminating manual deployments.

    10. Terraform – Infrastructure as Code (IaC) tool. Used to configure and manage AWS S3 remote backend and supporting infrastructure in a reproducible and version-controlled manner.
    
	
   ##	AWS Cloud – Cloud infrastructure platform:
  
    • EC2 hosts Jenkins, SonarQube container, and Apache Tomcat 9


    • S3 stores versioned build artifacts securely
  
    • IAM & VPC provide fine-grained security and network isolation


## Prerequisites


    - AWS account with billing enabled (used for provisioning infrastructure)

    - EC2 instance accessed via SSH (MobaXterm) for Jenkins and tooling setup

    - Basic Linux administration and shell scripting

    - Hands-on usage of Jenkins pipelines, Docker image builds, and Kubernetes deployments

    - Experience using Git for source control and Terraform for infrastructure provisioning

	
## PORT-IP'S


- JENKINS - 8080
 
- SONARQUBE - 9000


## Step 1: Launch EC2 Instances (CI/CD + Kubernetes)

1️ Jenkins & Tools Server

Go to AWS Console → EC2 → Launch Instance

Name: jenkins-server

OS: Amazon Linux 2023 AMI

Instance Type: m7i-flex.large (or t3.large if budget constrained)

Key pair: Create or use existing

Security Group: Allow All Traffic (0.0.0.0/0) (lab environment only)

Storage: 28 GB gp3 EBS

IAM Role: Attach role with AdministratorAccess (learning purpose)

Launch and connect via MobaXterm as ec2-user, then:

sudo su -

2️⃣ Kubernetes Instance (Cluster Setup)

Instance Type: t3.micro

Storage: 24 GB EBS volume

Used for Kubernetes cluster setup and containerized application deployment


### Step 2: Configure Terraform S3 Backend (State Management)

1. Terraform setup:
   ```bash
   sudo yum install -y yum-utils shadow-utils
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
   sudo yum install terraform
   ```

2. Create S3 bucket in AWS Console for Terraform state (e.g., `my-terraform-state-bucket-unique-name`) → note region

3. Edit `backend.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "your-unique-bucket-name"
       key            = "eks/terraform.tfstate"
       region         = "us-east-1"  # change if needed
       dynamodb_table = "terraform-lock"  # optional
       use_lockfile   = true
     }
   }
   ```

4. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```

## Step 3: Set Up Kubernetes Cluster Using kOps

Kubernetes is set up using kOps, with cluster state stored in the S3 backend configured above.

Install Kubernetes tools:

# Install kubectl
    curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

# Install kOps
    curl -Lo kops https://github.com/kubernetes/kops/releases/latest/download/kops-linux-amd64
    chmod +x kops
    sudo mv kops /usr/local/bin/


Create the Kubernetes cluster:

    kops create cluster --name ksn.k8s.local --zones=us-east-1a,us-east-1b --master-count=1 --master-size=m7i-flex.large --master-volume-size=30 --node-count=2 --node-size=c7i-flex.large --node-volume-size=28 --image=ami-068c0051b15cdb816 


Apply the cluster configuration:

    kops update cluster ksn.k8s.local --yes


kOps, the cluster is provisioned and becomes fully operational in approximately 5 minutes, enabling rapid environment setup.

<img width="1920" height="761" alt="cluster in aws" src="https://github.com/user-attachments/assets/8603b554-0565-41ed-a5c0-0227ae1af626" />


Verify cluster:

kubectl get nodes

---


Step 4: Connect Amazon S3 with Kubernetes Cluster

The Kubernetes cluster is integrated with Amazon S3 to allow pods and cluster components to securely access stored artifacts and state.

IAM Permissions

An IAM role with required S3 access is attached to the Kubernetes worker nodes

Permissions include read/write access to the designated S3 bucket

S3 as Cluster State Store

The same S3 bucket configured earlier is used as the kOps state store

    export KOPS_STATE_STORE=s3://my-kops-terraform-state-bucket


Application-Level Access

Kubernetes workloads can access S3 using AWS SDK/CLI via node IAM role

No hardcoded credentials are used inside containers

Verification

aws s3 ls s3://my-kops-terraform-state-bucket
kubectl get pods -A



### Step 3: Launch Jenkins

Open new terminal → SSH into same instance as root

```bash
sudo yum update –y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
sudo yum install java-17-amazon-corretto -y
sudo yum install jenkins git -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
sudo mkdir -p /var/tmp_disk
sudo chmod 1777 /var/tmp_disk
sudo mount --bind /var/tmp_disk /tmp
echo '/var/tmp_disk /tmp none bind 0 0' | sudo tee -a /etc/fstab
sudo systemctl mask tmp.mount
df -h /tmp
sudo systemctl restart jenkins
```

Access Jenkins: `http://<public-ip>:8080`  
Get initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Install **Suggested Plugins** → Create admin user (remember username/password)

---

### Step 4: Install Docker on Jenkins Server

```bash
# Docker
yum install docker -y && systemctl start docker
chmod 777 /var/run/docker.sock   # only for lab

# Lauching SonarQube through docker
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community
```

Access SonarQube: `http://<public-ip>:9000`  
Login: `admin` / `admin` → Change password →  

<img width="1900" height="871" alt="sonarqube-login" src="https://github.com/user-attachments/assets/0c36fb28-be4d-4a20-b71a-eba8810e2645" />


My Account → Security → Generate Token → Name: `mytoken` → Copy token

---

	 
### Step 5: Configure Jenkins Plugins

Manage Jenkins → Plugins → Available → Select below listed → Install and restart jenkins:
- Pipeline: Stage View
- SonarQube Scanner for Jenkins
- OWASP Dependency-Check
- Kubernetes
- Kubernetes CLI
- Docker Pipeline
- Deploy to container

---
- Restart jenkins

  
## Step 6: Configure Global Tools in Jenkins

Manage Jenkins → Tools →

1. **SonarQube Scanner** 
   - Name: `mysonar`
   - Install automatically

2. **Maven**
   - Name: `mymaven`
   - Install automatically (latest)

3. **Dependency-Check**
   - Name: `DP-Check`
   - Install automatically from GitHub

---

## Step 7: Configure SonarQube in Jenkins

Manage Jenkins → System → SonarQube servers
- Name: `mysonar`
- Server URL: `http://<public-ip>:9000`
- Server authentication token → Add → Secret Text → Paste token from SonarQube → ID: `sonar-token`

---
Manage Jenkins → System → Amazon s3 profiles → Profile name: mybucket

### Step 8: Create Jenkins Pipeline Job

Jenkins-Full-Pipeline  →  - <a href="https://github.com/Sravanikethari/Terraform-Driven-Artifact-Management-with-AWS-S3-Backend/blob/main/Jenkins_Pipeline">jenkins_pipeline</a>

New Item → Name: `tfproject` → Pipeline → OK

#### Pipeline Stages (Add one by one)

**Stage 1: Clean Workspace**
```groovy
cleanWs()
```

**Stage 2: Checkout Code**
```groovy
git 'https://github.com/Sravanikethari/dockerwebapp.git'
```

**Stage 3: SonarQube Analysis**

Use Pipeline Syntax → Snippet Generator → `withSonarQubeEnv` → Select `mysonar` → select → add → jenkins → add credentials → select → Generate:

```groovy
          steps{
                withSonarQubeEnv('mysonar'){
                    sh "mvn clean verify sonar:sonar -Dsonar.projectKey=MyProject"
          }
```

**Stage 4: Quality Gates**

Sonarqube server → project settings → webhooks → create → name: jenkins-integration →  url: jenkinsurl/sonarqube-webhook/ →  save  
Pipeline Syntax → `waitForQualityGate` → select → sonartoken → Generate:

```groovy
  script{
  waitForQualityGate abortPipeline: false, credentialsId: 'sonartoken'
}
```

**Stage 5: Code Build**

```groovy
sh 'mvn clean package'
sh 'cp -r target Docker-app'
```

**Stage 6: OWASP Dependency-Check**

- Get NVD API Key: https://nvd.nist.gov/developers/request-an-api-key → Apply → Get key from email
- In Jenkins → dependencyCheck → add → jenkins → Add Credentials → Secret Text → Paste API key → ID: `nvd-api-key`

Pipeline Syntax → dependencyCheck → select →  Additional arguments:

```
--scan ./ --disableYarnAudit --disableNodeAudit 
```
Then → dependencyCheckPublisher → Xml report pattern: `**/dependency-check-report.xml`

Generate pipeline →  script should look like this 

    dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', nvdCredentialsId: 'nvd', odcInstallation: 'DP-check'
      dependencyCheckPublisher pattern: '**/dependency-check-report.xml'

**Stage 7: Upload Artifact to S3**

AWS console
- Create IAM User with AmazonS3FullAccess
- Create access key → Copy Access Key & Secret
- In Jenkins → Manage Jenkins → Amazon S3 Profile → Add → Test & Save
- AWS console → s3 → create a bucket → copy bucket name remember region name

Pipeline Syntax → S3 Upload:

- File: `target/vprofile-v2.war` To check war file → cd /var/lib/jenkins/workspace/tfproject →  ll target
- Bucket: `your-artifact-bucket-name`
- Region: match your bucket region
- opt for no upload on build failure

      s3Upload consoleLogLevel: 'INFO', dontSetBuildResultOnFailure: false, dontWaitForConcurrentBuildCompletion: false, entries: [[bucket: 'amazn-s3-bucket-ksn', excludedFile: '', flatten: false, gzipFiles: false, keepForever: false, managedArtifacts: false, noUploadOnFailure: true, selectedRegion: 'ap-northeast-1', showDirectlyInBrowser: false, sourceFile: 'target/vprofile-v2.war', storageClass: 'STANDARD', uploadFromSlave: false, useServerSideEncryption: false]], pluginFailureResultConstraint: 'FAILURE', profileName: 'mybucket', userMetadata: []

**Stage 8: Build Docker Images**

```groovy
sh 'docker build -t appimage Docker-app'
sh 'docker build -t dbimage Docker-db'
```

**Stage 9: Trivy Image Scan**

First install Trivy on Jenkins server:
```bash
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin v0.67.2
```

In pipeline:

```groovy
sh 'trivy image appimage'
sh 'trivy image dbimage'
```

**Stage 10: Tag&push**

Push to Docker Hub

Add Docker Hub credentials in Jenkins → Pipeline syntax → with docker Registry → Registry credentials → add →  jenkins → Username: Dockerhub username, Password: Dockerhub password → (ID: `dockerhub`) → select → dockerhub

```groovy
docker.withRegistry('https://index.docker.io/v1/', 'dockerhub') {
  sh 'docker tag appimage yourusername/vprofile-app:latest'
  sh 'docker tag dbimage yourusername/vprofile-db:latest'
  sh 'docker push yourusername/vprofile-app:latest'
  sh 'docker push yourusername/vprofile-db:latest'
}
```
It should look like this

      script{
                withDockerRegistry(credentialsId: 'dockerhub') {
                    sh 'docker tag appimage sravani93/terraformproject:app'
                    sh 'docker tag dbimage sravani93/terraformproject:db'
                    sh 'docker push sravani93/terraformproject:app'
                    sh 'docker push sravani93/terraformproject:db'

Checking DockerHub Registry images uploaded in the directed repo

<img width="1904" height="876" alt="dockerhub-images" src="https://github.com/user-attachments/assets/7a984944-334f-4ab1-a4df-c97c0627cb0d" />



**Stage 11: Configure Argo CD for GitOps Deployment**

Install and Access Argo CD (GitOps CD)
1️ Install Argo CD

    kubectl create namespace argocd

    kubectl apply -n argocd \
    -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml


Verify installation:

kubectl get all -n argocd

2️ Expose Argo CD Server (LoadBalancer)

    kubectl patch svc argocd-server -n argocd \
    -p '{"spec": {"type": "LoadBalancer"}}'


    Install jq (required to parse JSON output):

    sudo yum install jq -y


Fetch the Argo CD LoadBalancer URL:

    kubectl get svc argocd-server -n argocd -o json \
    | jq -r '.status.loadBalancer.ingress[0].hostname'
  

⏳ It may take 1–2 minutes for the LoadBalancer URL to be available.

3️  Get Argo CD Admin Password

     kubectl -n argocd get secret

	 <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/e3dcd03d-04ab-406a-be53-5340cb1263bf" />

Git Repository for Argo CD (GitOps)

This project follows a GitOps-based deployment model using Argo CD, where Kubernetes application manifests are stored in a dedicated Git repository and treated as the single source of truth.

Repository Structure

    k8s-manifests/
    ├── deployment.yml
    └── service.yml

Deployment Workflow

Kubernetes manifests are committed and version-controlled in Git

Argo CD continuously monitors the repository for changes

Any update to the manifest files is automatically synchronized to the Kubernetes cluster

Manual kubectl apply commands are not required after Argo CD is configured

This approach ensures consistent, auditable, and automated deployments while eliminating configuration drift.


<img width="1920" height="974" alt="ksn result" src="https://github.com/user-attachments/assets/27dcf541-41ba-4a96-ad24-3232fa901c0b" />


## Conclusion

This project demonstrates a cloud-native, production-ready CI/CD and deployment workflow by combining Infrastructure as Code (Terraform), containerization, Kubernetes, and GitOps with Argo CD. The solution eliminates manual deployments, enforces secure and version-controlled configurations, and ensures consistent, automated delivery through Jenkins-driven CI pipelines and Argo CD–managed Kubernetes deployments. By leveraging AWS services such as S3, IAM, and Kubernetes infrastructure, the project achieves scalability, auditability, and reliable continuous delivery.
 
---

# 👨‍💻 Author & Support🛠️
This project is maintained by Sravani💡. Your feedback and contributions are welcome!

# 📧 Connect with me:

GitHub: https://github.com/Sravanikethari

LinkedIn: https://linkedin.com/in/sravani-k-082838350

# ⭐ Support the Project
If you found this project helpful, please consider:


•	Starring ⭐ the repository

•	Sharing it with your network

•	Contributing to its improvement


