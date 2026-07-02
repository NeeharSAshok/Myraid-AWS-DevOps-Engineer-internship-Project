# Architecture Reference & Data Flow

This document details the system design, network infrastructure, and delivery pipeline for the DevOps Technical Assignment.

## System Architecture

The infrastructure runs within the AWS Free Tier, leveraging custom VPC configurations and least-privilege access rules to host the containerized API.

```mermaid
graph TD
    User([End User / client]) -->|HTTP Port 80 / HTTPS Port 443| IGW[Internet Gateway]
    IGW -->|VPC Route Table| Nginx[Nginx Reverse Proxy]
    
    subgraph VPC ["AWS VPC (10.0.0.0/16)"]
        subgraph PublicSubnet ["Public Subnet (10.0.1.0/24)"]
            subgraph EC2 ["EC2 Instance (t2.micro - Ubuntu)"]
                Nginx -->|Proxy Pass http://localhost:8000| Docker["Docker Engine"]
                subgraph Docker ["Docker Container Runtime"]
                    FastAPI["FastAPI Web Server"]
                end
                
                CloudWatchAgent["CloudWatch Agent"] -->|Metrics / Logs| CloudWatch[AWS CloudWatch]
                Cron["Daily Backup Cron Job"] -->|Compress & Upload| S3Upload["AWS CLI Upload"]
            end
        end
    end
    
    S3Upload -->|SSL/TLS encrypted| S3["AWS S3 Bucket (Private, KMS encrypted)"]
    EC2Role[IAM Instance Profile Role] -.->|Least-Privilege Policy| S3
    
    style VPC fill:#f9f9f9,stroke:#333,stroke-width:1px
    style PublicSubnet fill:#e1f5fe,stroke:#03a9f4,stroke-width:1px
    style EC2 fill:#ffe0b2,stroke:#ff9800,stroke-width:1px
    style Docker fill:#e0f2f1,stroke:#009688,stroke-width:1px
```

### Components Summary

1. **Virtual Private Cloud (VPC)**: Custom IP range (`10.0.0.0/16`) isolating all subnets from the default VPC network.
2. **Public Subnet**: Holds the EC2 instance, provisioned with an Elastic IP/Public IP, routing out through the Internet Gateway (IGW).
3. **Nginx Reverse Proxy**: Receives connection requests on port 80/443, handles SSL termination, and routes traffic back to the local FastAPI port (`8000`).
4. **FastAPI Docker Container**: The Python application packaged and run inside Docker, securing separation from the host system dependencies.
5. **AWS S3 Backup Bucket**: Log and database snapshot storage. Configured with Versioning, Encryption (SSE-AES256), and Public Access Block.
6. **IAM Role**: Role attached to the EC2 instance providing temporary credentials for write access to the S3 bucket.
7. **CloudWatch Monitoring**: Receives performance counters (CPU, RAM usage) and standard service error logs to trigger alarms.

---

## CI/CD Pipeline Workflow

The repository uses GitHub Actions to automate testing, compilation, and deployment on every git push to the main branch.

```mermaid
sequenceDiagram
    autonumber
    actor Dev as Developer
    participant Git as GitHub Repo
    participant Runner as GitHub Runner
    participant GHCR as GitHub Container Registry (GHCR)
    participant EC2 as AWS EC2 Server

    Dev->>Git: git push origin main
    Git->>Runner: Trigger Action Workflow
    activate Runner
    Runner->>Runner: Checkout Repository
    Runner->>Runner: Run Linting (flake8)
    Runner->>Runner: Run Unit Tests (pytest)
    
    Note over Runner: If tests/lint pass, build Docker image
    Runner->>Runner: Build Docker Image
    Runner->>GHCR: Login & Push Image (ghcr.io/username/repo:main)
    
    Note over Runner: Deploy phase via SSH
    Runner->>EC2: Connect via SSH (SSH Key)
    activate EC2
    EC2->>GHCR: Docker Login & Pull Image
    EC2->>EC2: Stop & Remove old container
    EC2->>EC2: Run new container (Port 8000:8000)
    EC2->>EC2: Prune dangling docker images
    deactivate EC2
    
    Runner-->>Dev: Pipeline Status: Success
    deactivate Runner
```
