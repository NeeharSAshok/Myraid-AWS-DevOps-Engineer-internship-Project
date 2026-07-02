# Security Configuration & Compliance Summary

This document describes the security framework implemented in the architecture to align with AWS and industry security best practices.

---

## 1. Shared Responsibility Model Implementation

The infrastructure is split into distinct zones, ensuring that security is applied at every level of the stack.

| Category | Managed By | Implemented Security Control |
| :--- | :--- | :--- |
| **Network Security** | Terraform (IaC) | Custom VPC, Public/Private boundary separation, restricted Security Groups. |
| **Identity & Access** | IAM | AWS IAM Instance Profiles, S3-restricted Policies (Least-Privilege). |
| **Data Encryption** | S3 Config | Server-Side Encryption (SSE-AES256), Versioning, Public Access Blocked. |
| **Application Layer**| FastAPI Code | Input boundary validations, container sandbox isolation via Docker. |
| **Host Configuration**| User Data Script | Firewall configurations (Nginx proxying), SSH restricted access. |

---

## 2. Infrastructure & Network Security

### Virtual Private Cloud Isolation
- The application resides in a custom-built Virtual Private Cloud (VPC) with a designated CIDR range (`10.0.0.0/16`), isolating the networking configuration from the AWS default space.
- A single public subnet (`10.0.1.0/24`) is created to house the EC2 instance, controlled by an Internet Gateway (IGW) route mapping.

### Security Group Firewall Configuration
The EC2 instance is guarded by a stateful security group firewall enforcing ingress controls:
- **Port 80 (HTTP)**: Open globally (`0.0.0.0/0`) to accept public web traffic, routed via Nginx.
- **Port 443 (HTTPS)**: Open globally (`0.0.0.0/0`) for encrypted client communication.
- **Port 22 (SSH)**: Allowed for remote administrative commands. *Recommendation: Override this in production to point solely to your organization's VPN/CIDR.*
- **Outbound (Egress)**: Allowed dynamically (`0.0.0.0/0`) to allow security patches, dependency installations, and container image fetching.

---

## 3. Identity and Access Management (IAM)

To prevent security risks associated with hardcoding API keys:
- **Instance Profile Role**: An IAM role is assigned to the EC2 server (`devops-assignment-ec2-s3-access-role`). The server acquires dynamic, short-lived security tokens via the AWS Instance Metadata Service (IMDS).
- **Least-Privilege Policy**: The attached policy (`devops-assignment-s3-access-policy`) explicitly limits access to the specific project S3 bucket name. The permissions are constrained strictly to write/read commands (`s3:PutObject`, `s3:GetObject`, `s3:ListBucket`, `s3:DeleteObject`) and block full admin privileges (`s3:*`).

---

## 4. S3 Storage Security

The S3 bucket configuration acts as a secure backup repository:
- **Public Access Block**: A strict public access block prevents the bucket from serving files to the public internet, even if ACLs are mistakenly updated.
- **Encryption-at-Rest**: Enforces AES-256 server-side encryption (`SSE-AES256`) to automatically encrypt stored server access logs.
- **Versioning**: Enabled to protect against accidental file deletion or ransomware attacks.

---

## 5. Application Security & Containerization

- **Docker Sandbox**: The application runs inside an isolated container namespace. In the event of an application exploit, the attacker is confined to the container filesystem rather than acquiring immediate access to the host server.
- **Validation Defenses**: The compute endpoint validation limits mathematical recursion depth (e.g., Fibonacci calculation restricted to `n <= 40`) and memory creation size (`size_mb <= 100`) to mitigate denial of service (DoS) attacks on CPU and RAM.
