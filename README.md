# DevOps Engineer Technical Assignment Submission

This repository contains the complete codebase, infrastructure as code (IaC), CI/CD pipelines, load testing scripts, and architecture documentation for the DevOps Engineer Technical Assignment.

---

## 📺 Demo & Implementation Video

Click the badge below to watch a 7-minute walkthrough of the AWS infrastructure, the CI/CD pipeline, and the performance load tests:

[![Watch the video](https://img.shields.io/badge/Google%20Drive-Watch%20Demo%20Video-blue?style=for-the-badge&logo=googledrive)](https://drive.google.com/file/d/13EGQJB_0iXOiQh7Ap5axpv5VKjdo9Ujr/view?usp=sharing)

---

## 📁 Repository Structure

```text
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD Pipeline
├── app/
│   ├── Dockerfile              # Docker image definition
│   ├── main.py                 # FastAPI application and endpoints
│   ├── requirements.txt        # Python package requirements
│   └── test_main.py            # Unit tests using Pytest
├── terraform/
│   ├── ec2.tf                  # EC2 Instance and User Data scripts
│   ├── iam.tf                  # IAM Roles & S3 Least Privilege Policies
│   ├── outputs.tf              # Terraform outputs
│   ├── providers.tf            # Provider version requirements
│   ├── s3.tf                   # Private S3 Backup Bucket and blocks
│   ├── security_groups.tf      # Firewall configuration (HTTP, HTTPS, SSH)
│   ├── variables.tf            # Deployment configuration inputs
│   └── vpc.tf                  # Custom VPC, public subnets & routing
├── load-testing/
│   └── load_test.js            # k6 load test configuration script
└── docs/
    ├── ARCHITECTURE.md         # Mermaid system design and workflow diagrams
    ├── DEPLOYMENT_GUIDE.md     # Setup, provisioning, and pipeline guide
    ├── SECURITY_SUMMARY.md     # IAM configurations & firewall compliance
    ├── LOAD_TESTING_REPORT.md  # Stress test results and optimizations
    └── FINAL_REPORT.md         # Final comprehensive project report
```

---

## 🛠️ Tech Stack & Key Choices

- **Web Application**: **FastAPI (Python)** — High performance, asynchronous endpoints, built-in interactive OpenAPI UI.
- **Infrastructure as Code**: **Terraform** — Modular, predictable, state-tracked resource definitions.
- **Reverse Proxy**: **Nginx** — Reverse-proxy configuration for local request routing and SSL termination.
- **Continuous Integration / Continuous Deployment**: **GitHub Actions** — Native GitHub automation using Docker build cache and secure environment secrets.
- **Container Registry**: **GitHub Container Registry (GHCR)** — Secure container storage with automatic version control.
- **Load Testing**: **k6 (JavaScript)** — Lightweight, command-line driven performance simulation.
- **Monitoring**: **AWS CloudWatch** — Host-level agent configuration for real-time dashboards and CPU utilization alerts.

---

## 🚀 Quick Start & Documentation Links

1. **Architecture & System Flows**: Refer to [docs/ARCHITECTURE.md](file:///docs/ARCHITECTURE.md) to inspect network layouts and CI/CD workflow diagrams.
2. **Infrastructure Provisioning**: Follow [docs/DEPLOYMENT_GUIDE.md](file:///docs/DEPLOYMENT_GUIDE.md) to set up AWS credentials, run Terraform, configure GitHub Secrets, and activate the deployment pipeline.
3. **Security Details**: Refer to [docs/SECURITY_SUMMARY.md](file:///docs/SECURITY_SUMMARY.md) to understand IAM profiles, firewall rules, and encryption settings.
4. **Performance Tests**: View [docs/LOAD_TESTING_REPORT.md](file:///docs/LOAD_TESTING_REPORT.md) to review peak load throughput, latency metrics, and performance optimizations.
5. **Final Project Submission**: For the final overview containing setup steps, bottlenecks, challenges, and improvements, read [docs/FINAL_REPORT.md](file:///docs/FINAL_REPORT.md).
