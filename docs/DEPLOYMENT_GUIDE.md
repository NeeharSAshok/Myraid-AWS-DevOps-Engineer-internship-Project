# AWS Infrastructure & Application Deployment Guide

This guide describes the manual and automated steps required to provision the AWS cloud infrastructure and configure the automated CI/CD pipeline.

---

## Prerequisites

Before beginning, ensure you have the following:
1. An **AWS Account** with Free Tier access.
2. **Terraform CLI** (v1.0.0+) installed locally.
3. **AWS CLI** installed and configured (`aws configure` with access key and secret key).
4. **Git** installed locally.
5. A **GitHub Repository** to host your code and run the GitHub Actions workflow.

---

## Step 1: AWS SSH Key Pair Setup

To enable remote SSH connections to the EC2 server:
1. Log in to the [AWS Management Console](https://console.aws.amazon.com/).
2. Navigate to **EC2 Dashboard** -> **Network & Security** -> **Key Pairs**.
3. Click **Create key pair**.
4. Name it **`devops-ssh-key`**, select format **`pem`**, and download the private key file. Save it securely.

---

## Step 2: Terraform Infrastructure Provisioning

1. Navigate to the `/terraform` directory in your local terminal:
   ```bash
   cd terraform
   ```
2. Initialize the project (downloads AWS providers):
   ```bash
   terraform init
   ```
3. Preview the infrastructure modifications:
   ```bash
   terraform plan
   ```
4. Deploy the infrastructure to AWS:
   ```bash
   terraform apply -auto-approve
   ```
5. Note the outputs shown in the terminal:
   - `ec2_public_ip` (The IP to access the application and SSH into)
   - `s3_bucket_name` (The unique bucket name generated for logs and backups)

---

## Step 3: Setting Up GitHub Repository Secrets

The GitHub Actions workflow requires connection details to securely deploy the Docker images to your newly created EC2 instance.

1. Navigate to your repository page on GitHub.
2. Go to **Settings** -> **Secrets and variables** -> **Actions**.
3. Create the following **Repository Secrets**:
   - `EC2_HOST`: The value of `ec2_public_ip` from the Terraform output.
   - `EC2_SSH_KEY`: The entire text contents of the private key (`devops-ssh-key.pem`) downloaded in Step 1.

---

## Step 4: Activating the CI/CD Pipeline

1. Add, commit, and push the files to your repo's `main` branch:
   ```bash
   git add .
   git commit -m "feat: setup app, tf infrastructure, and pipeline"
   git push origin main
   ```
2. Go to the **Actions** tab in your GitHub repository to monitor the runner execution.
3. Once completed successfully:
   - Open your browser and navigate to `http://<ec2_public_ip>/` to check the API response.
   - View the OpenAPI interactive UI docs by going to `http://<ec2_public_ip>/docs`.

---

## Step 5: HTTPS Configuration (Optional but Recommended)

To configure HTTPS securely using Let's Encrypt:
1. Point your domain (e.g., `api.yourdomain.com`) to the `ec2_public_ip` using an A Record in your DNS provider (e.g., Route 53, Cloudflare).
2. SSH into your EC2 server:
   ```bash
   ssh -i /path/to/devops-ssh-key.pem ubuntu@<ec2_public_ip>
   ```
3. Install Certbot for Nginx:
   ```bash
   sudo apt-get install certbot python3-certbot-nginx -y
   ```
4. Obtain and install the SSL certificate:
   ```bash
   sudo certbot --nginx -d api.yourdomain.com
   ```
5. Follow the prompts to configure automatic HTTP-to-HTTPS redirects. Nginx will automatically be updated with the SSL settings.

---

## Step 6: Enable CloudWatch Agent (Host-Level Monitoring)

To collect memory usage and advanced disk space metrics from the EC2 instance:
1. SSH into the EC2 instance.
2. Download the Amazon CloudWatch Agent package:
   ```bash
   wget https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
   sudo dpkg -i -E ./amazon-cloudwatch-agent.deb
   ```
3. Configure the CloudWatch Agent using the wizard or a config file located at `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json`:
   ```bash
   sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
   ```
4. Start the agent:
   ```bash
   sudo systemctl start amazon-cloudwatch-agent
   ```
