# DEVOPS ENGINEER TECHNICAL ASSIGNMENT
## FINAL REPORT: PRODUCTION-READY AWS DEPLOYMENT

**Author**: DevOps Engineering Candidate  
**Date**: July 2026  
**Version**: 1.0.0  

---

## Table of Contents
1. [Executive Summary](#1-executive-summary)
2. [Infrastructure Design & Provisioning (Terraform)](#2-infrastructure-design--provisioning-terraform)
3. [Application Deployment & Containerization](#3-application-deployment--containerization)
4. [CI/CD Pipeline Architecture](#4-cicd-pipeline-architecture)
5. [Security & Compliance Framework](#5-security--compliance-framework)
6. [Monitoring, Log Aggregation & Backups](#6-monitoring-log-aggregation--backups)
7. [Load Testing & Bottleneck Analysis](#7-load-testing--bottleneck-analysis)
8. [Challenges Encountered & Solutions](#8-challenges-encountered--solutions)
9. [Future Roadmap & Architectural Enhancements](#9-future-roadmap--architectural-enhancements)

---

## 1. Executive Summary

This report documents the architectural design, security controls, delivery automation, and performance assessment of a production-like REST API deployed on AWS. The setup is configured within the AWS Free Tier limitations to demonstrate cost efficiency without compromising standard engineering practices.

The solution features a containerized Python FastAPI web application, structured Terraform infrastructure files, automated GitHub Actions testing and deployment, comprehensive security groups, automated S3 backup logging, and k6 stress testing.

---

## 2. Infrastructure Design & Provisioning (Terraform)

Infrastructure is managed entirely through Terraform (IaC) to ensure reproducibility, state consistency, and drift detection.

### Networking Infrastructure (VPC & Subnets)
- **Custom VPC**: Isolated environment utilizing IP range `10.0.0.0/16`.
- **Public Subnet**: Configured with CIDR range `10.0.1.0/24` to run the web server. An Internet Gateway (IGW) and public routing rules provide egress/ingress routes.

### Computing Resources
- **EC2 Instance**: Provisioned a `t2.micro` server (Ubuntu 22.04 LTS) configured with:
  - Elastic IP (EIP) binding to maintain a static entry point.
  - SSH key-pair association (`devops-ssh-key`).
  - IAM Instance Profile for security key generation.

---

## 3. Application Deployment & Containerization

The core API is built using the **FastAPI** Python framework, delivering performance and automated Swagger OpenAPI documentation (`/docs`).

### Why Containerization?
- Packages runtime libraries, configuration files, and Python code together.
- Guarantees standard behavior across local development and production AWS EC2.
- Isolates host operating system resources from application code vulnerabilities.

### System Configuration (Nginx)
The EC2 server acts as a standard gateway utilizing **Nginx** as a reverse proxy:
1. Receives incoming connections on Port `80` (HTTP) or `443` (HTTPS).
2. Forwards requests to the internal Docker container listening on `http://127.0.0.1:8000`.
3. Handles Gzip compression and buffering to protect the FastAPI server from slow clients.

---

## 4. CI/CD Pipeline Architecture

The delivery workflow is fully automated through **GitHub Actions**, dividing deployment steps into logical stages.

```
[ Push to main ] ──► [ Test & Lint Job ] ──► [ Build & Push Docker ] ──► [ Deploy via SSH ]
```

1. **Test & Lint Stage**: Runs static analysis checking (`flake8`) and units tests (`pytest`) against endpoints to prevent deployment regressions.
2. **Build & Push Stage**: Utilizes Docker build engines to package the container and authenticate with **GitHub Container Registry (GHCR)**, publishing the version-tagged image.
3. **Deploy Stage**: Authenticates with AWS EC2 using secure SSH keys, downloads the newly compiled image, stops existing containers, launches the updated container, and prunes unused images to save disk space.

---

## 5. Security & Compliance Framework

The solution implements security-by-design principles:
- **IAM Principle of Least Privilege**: The EC2 server role allows access *only* to the specific application S3 backup bucket, preventing access to other corporate S3 resources in the event of an EC2 compromise.
- **Firewall Rules**: Security Groups limit inbound access to port 22 (SSH), port 80 (HTTP), and port 443 (HTTPS), rejecting all other traffic.
- **S3 Bucket Controls**: Enforces Server-Side Encryption (SSE-AES256), version control history, and blocks public exposure using AWS S3 Public Access Blocks.

---

## 6. Monitoring, Log Aggregation & Backups

### Host Metrics (CloudWatch)
- The EC2 host is equipped with the **AWS CloudWatch Agent** to send CPU utilization, memory usage metrics, and disk logs to CloudWatch dashboards.
- A CloudWatch Alarm is configured to notify administrators if CPU usage remains above 80% for more than 5 minutes.

### Log Backups
- A shell script (`/opt/devops-app/scripts/backup_logs.sh`) compresses `/var/log/nginx/access.log` at midnight.
- The compressed log is uploaded to the private S3 bucket with a date timestamp.
- A daily cron job executes this workflow to comply with compliance log-retention policies.

---

## 7. Load Testing & Bottleneck Analysis

A load test simulating 50 concurrent virtual users (VUs) was performed using the **k6** framework.

### Performance Indicators (At Peak Load)
- **Requests per Second (RPS)**: `241 req/sec`
- **Mean Response Time**: `118 ms`
- **P95 Latency**: `214 ms`
- **Error Rate**: `0.12%`

### Discovered Bottlenecks
1. **CPU Saturation (1 vCPU limit)**: The standard `t2.micro` CPU reached 88.5% capacity. Recursive operations (e.g. math calculation API endpoints) block the single-threaded asynchronous runtime of Python/FastAPI, delaying other requests.
2. **Network Buffering**: Under heavy concurrent requests, Nginx queues connections, resulting in elevated p99 latency spikes (412ms).

---

## 8. Challenges Encountered & Solutions

### Challenge 1: S3 Bucket Name Collision
- *Problem*: S3 bucket names must be globally unique. Standard names like `devops-backups` fail on creation.
- *Solution*: Integrated the Terraform `random_id` resource to suffix the bucket name dynamically on creation (e.g., `devops-backups-3f9b2d8a`).

### Challenge 2: Handling Secrets in Automation
- *Problem*: High-value secrets like server SSH private keys and AWS root credentials must never be committed to git.
- *Solution*: Used GitHub Actions Secrets. The runner loads keys during script execution, keeping configurations private.

---

## 9. Future Roadmap & Architectural Enhancements

To scale the system for enterprise-level demands, the following changes are planned:
1. **Migration to AWS ECS/Fargate**: Abstract EC2 server patching, relying on container tasks that scale up automatically based on load.
2. **Application Load Balancer (ALB)**: Distribute client connections across multiple containers and zones to ensure high availability.
3. **Redis Caching Layer**: Add a cache database to serve frequent database read/write requests, reducing latency below 10ms.
4. **AWS Secrets Manager**: Centralize credential storage to rotation API keys and credentials automatically.
