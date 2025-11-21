# Terraform-Driven-Artifact-Management-with-AWS-S3-Backend
Project Overview

This project demonstrates a complete end-to-end CI/CD pipeline for a Java-based application using Jenkins, Maven, SonarQube, Docker, Trivy, Terraform, and AWS services. The pipeline automates code quality checks, dependency scanning, application packaging, containerization, security scanning, and deployment.

2. Architecture Diagram

(Insert your architecture diagram here)

3. Introduction

In today’s fast-paced development environment, Continuous Integration and Continuous Deployment (CI/CD) are essential for delivering software quickly and reliably. By automating build, test, and deployment processes, teams can improve code quality, enhance collaboration, and accelerate release cycles.

This guide walks through building a real-time CI/CD pipeline for a Java application and deploying it onto an Apache server. We use Jenkins, Maven, and Git to automate the workflow, ensuring that code is compiled, tested, packaged, and deployed with minimal manual effort.

To manage infrastructure efficiently, we use Terraform as Infrastructure as Code (IaC), enabling consistent, version-controlled provisioning of cloud resources. Our environment runs on AWS, leveraging services like EC2 (for Jenkins, Apache/Tomcat, SonarQube), S3 (for artifact storage), and EKS (for container orchestration).

By combining CI/CD automation with Terraform and AWS, we create a scalable, repeatable, and production-ready deployment pipeline for Java applications—ensuring faster and more reliable software delivery.

4. Technologies Used
Technologies Used

Technologies Used
1.	Maven – Application development and build management tool. Compiles code, runs tests, manages dependencies, and packages the Java application into a .war file.

   
2.	Jenkins – CI/CD orchestration engine running on AWS EC2. Automatically triggers on GitHub push, executes the full pipeline, and provides complete visibility and control.

	
3.	GitHub – Source code repository and version control system. Hosts the application code, Jenkinsfile, Dockerfile, and Terraform scripts while instantly triggering Jenkins via webhook.

	
4.	SonarQube (via Docker) – Static code analysis platform. Detects bugs, code smells, security vulnerabilities, duplication, and enforces quality gates before deployment.

	
5.	OWASP Dependency-Check – Dependency vulnerability scanner. Checks all libraries in pom.xml against known vulnerability databases and fails the build on critical issues.

	
6.	Docker – Containerization platform. Builds lightweight, consistent images of the application for reproducible environments (optional deployment path).

	
7.	Trivy – Container image security scanner. Quickly identifies OS and application-level vulnerabilities in Docker images before pushing to registry.

  
8.	Terraform – Infrastructure as Code (IaC) tool. Automatically provisions and manages AWS EC2, S3, VPC, IAM roles, and security groups in a fully reproducible way.

	
9.	AWS Cloud – Cloud infrastructure platform:
  
    • EC2 hosts Jenkins, SonarQube container, and Apache Tomcat 9

    • S3 stores versioned build artifacts securely
  
    • IAM & VPC provide fine-grained security and network isolation




5. Prerequisites

## Prerequisites
- AWS Account with billing enabled
- MobaXterm or any SSH client
- Basic knowledge of AWS, Linux, Jenkins, Docker

## PORT-IP'S
- JENKINS - 8080
- SONARQUBE - 9000
- TOMCAT - 8080
---



### Step 1: Launch EC2 Instance (Jenkins + Tools Server)

1. Go to AWS Console → EC2 → Launch Instance
2. Name: `jenkins-terraform' (or any)
3. OS: **Amazon Linux 2023 AMI kernel-6.1**
4. Instance Type: **m7i-flex.large** (or t3.large if budget constrained)
5. Key pair: Create or use existing
6. Security Group: Allow **All Traffic** (0.0.0.0/0) → only for learning/lab
7. Storage: 28 GB gp3 EBS volume
8. IAM Role: Create new role with **AdministratorAccess** (for learning only)
9. Launch instance
10. Connect via MobaXterm as `ec2-user`, then switch to root:
     ```bash
    sudo su -
    ```
 11. Launch another with c7i-flex.large for TOMCAT everything same expect IAM configuration   

### Step 2: JENKINS SERVER → Provision EKS Cluster using Terraform

1. Install Terraform:
   ```bash
   sudo yum install -y yum-utils shadow-utils
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
   sudo yum install terraform
   ```




3. Create S3 bucket in AWS Console for Terraform state (e.g., `my-terraform-state-bucket-unique-name`) → note region

4. Edit `backend.tf`:
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

5. Edit `main.tf`:
   - Line ~89: Desired/Min/Max capacity → `desired_size = 2`, `min_size = 2`, `max_size = 4`
   - Line ~93: Change instance type to `c7i-flex.large` 

6. Run Terraform:
   ```bash
   terraform init
   terraform plan
   terraform apply --auto-approve
   ```
   Wait 15–20 mins for EKS cluster to be ready.

7. Verify:
   ```bash
   terraform state list
   aws eks update-kubeconfig --name <cluster-name> --region us-east-1
   kubectl get nodes
   ```

---

11. Configuring Jenkins Plugins

Add Maven tool

Add JDK

Add SonarQube server details

Set Docker Hub credentials

12. GitHub Source Code Integration

Create GitHub repo

Add Jenkins webhook

Configure Jenkins Pipeline to pull code

13. SonarQube Code Quality Analysis

Configure SonarQube in Jenkins

Add sonar-project.properties

Perform static code analysis during pipeline

14. Implementing OWASP Dependency Check

Identify vulnerable dependencies

Generate HTML or XML reports

Fail build on high-severity issues (optional)

15. Maven Build and Artifact Generation

Run mvn clean install

Package application as .jar or .war

Upload artifacts to AWS S3

16. Artifact Storage in Amazon S3

Store versioned build artifacts

Secure using IAM policies

Retrieve during deployment stage

16.1 Terraform-Driven Artifact Management with AWS S3 Backend

Tools: AWS S3, IAM, Terraform, Jenkins, Shell Scripting

Automated provisioning of versioned S3 buckets and fine‑grained IAM policies via Terraform, integrating artifact storage securely within Jenkins pipelines.

Eliminated manual uploads entirely and improved artifact retrieval speeds by over 50%, while implementing lifecycle and versioning policies for cost control.

17. Docker Image Build & Trivy Security Scan

Build Docker image using Dockerfile

Scan image with Trivy

Fail pipeline on critical vulnerabilities

18. Pushing Images to Docker Hub

Authenticate using Jenkins credentials

Push versioned image tags

19. Deploying Java Application

You can deploy to:

Tomcat/Apache on EC2

Docker container on EC2

Kubernetes on EKS (optional)

20. EKS Cluster Setup (Optional)

Provision EKS using Terraform

Deploy application using Kubernetes manifests

21. Jenkins Pipeline (CI/CD)

Add your full Jenkinsfile here.

22. Testing and Verification

Verify Jenkins stages

Check SonarQube reports

Validate S3 uploads

Test application deployment

23. Troubleshooting Guide

Jenkins agent connectivity issues

Docker permission errors

AWS credential issues

SonarQube scanner configuration errors

24. Best Practices and Security Considerations

Use IAM roles instead of access keys

Enable S3 bucket versioning

Use Trivy to detect security flaws

Maintain least-privilege access

25. Conclusion

This project demonstrates a complete CI/CD automation system for Java applications using industry-standard tools and best practices in cloud-native DevOps.


26. IMAGES/OUTPUTS

Full Deploy:

<img width="1900" height="802" alt="Full-deploy" src="https://github.com/user-attachments/assets/335bcd0b-0e74-4618-855a-edac2c808237" />

Sonarqube-login-page:

<img width="1900" height="871" alt="sonarqube-login" src="https://github.com/user-attachments/assets/9186537d-65a6-4ce1-8830-06caaf971b03" />

Tomcat: 

<img width="1902" height="874" alt="tomcat-home" src="https://github.com/user-attachments/assets/0aefd132-12f8-423d-acbf-3de506b40f2b" />

Dockerhub:

<img width="1904" height="876" alt="dockerhub-images" src="https://github.com/user-attachments/assets/25ae967c-3ea9-4ac0-a24a-b77dc4da7ebe" />

Output:

<img width="1920" height="872" alt="live-page" src="https://github.com/user-attachments/assets/b0a33276-6fb4-4058-a8a9-ffeb8e59a328" />


27. Future Enhancements

Integrate ArgoCD for GitOps

Add monitoring (Prometheus & Grafana)

Configure Blue/Green deployments

28. Author / Maintainer

fly – Project Owner
