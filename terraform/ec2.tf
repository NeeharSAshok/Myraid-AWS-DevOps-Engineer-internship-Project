# Fetch latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

# Generate a new private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Register the public key in AWS EC2
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

# Save the private key to a local PEM file on your computer
resource "local_file" "private_key_file" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/devops-ssh-key.pem"
  file_permission = "0600"
}

# EC2 Instance for Web App
resource "aws_instance" "app_server" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = var.instance_type
  key_name             = aws_key_pair.generated_key.key_name
  subnet_id            = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true

  # User data script to initialize the server, install Nginx & Docker, and configure automated backups
  user_data = <<-EOF
              #!/bin/bash
              set -ex

              # Update packages
              apt-get update -y
              apt-get upgrade -y

              # Install dependencies
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common nginx unzip awscli

              # Install Docker
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              apt-get update -y
              apt-get install -y docker-ce docker-ce-cli containerd.io
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # Configure Nginx as Reverse Proxy
              cat << 'NGINX_CONF' > /etc/nginx/sites-available/default
              server {
                  listen 80 default_server;
                  listen [::]:80 default_server;

                  server_name _;

                  location / {
                      proxy_pass http://localhost:8000;
                      proxy_http_version 1.1;
                      proxy_set_header Upgrade $http_upgrade;
                      proxy_set_header Connection 'upgrade';
                      proxy_set_header Host $host;
                      proxy_cache_bypass $http_upgrade;
                      proxy_set_header X-Real-IP $remote_addr;
                      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  }
              }
              NGINX_CONF

              systemctl restart nginx

              # Create a script for S3 log backup
              mkdir -p /opt/devops-app/scripts
              cat << 'BACKUP_SCRIPT' > /opt/devops-app/scripts/backup_logs.sh
              #!/bin/bash
              TIMESTAMP=\$(date +"%Y%m%d_%H%M%S")
              BUCKET_NAME="${aws_s3_bucket.backups.id}"
              LOG_FILE="/var/log/nginx/access.log"
              BACKUP_FILE="/tmp/nginx_access_\$TIMESTAMP.log.gz"

              # Compress log
              gzip -c \$LOG_FILE > \$BACKUP_FILE

              # Upload to S3
              aws s3 cp \$BACKUP_FILE s3://\$BUCKET_NAME/backups/nginx_access_\$TIMESTAMP.log.gz

              # Clean up
              rm \$BACKUP_FILE
              BACKUP_SCRIPT

              chmod +x /opt/devops-app/scripts/backup_logs.sh

              # Add cron job for daily backups at midnight
              (crontab -l 2>/dev/null; echo "0 0 * * * /opt/devops-app/scripts/backup_logs.sh") | crontab -

              # Run initial dummy web container to serve health check before CI/CD runs
              docker run -d --name fastapi-app -p 8000:8000 --restart always python:3.10-slim python -c "
              from http.server import HTTPServer, BaseHTTPRequestHandler
              import json
              class Handler(BaseHTTPRequestHandler):
                  def do_GET(self):
                      self.send_response(200)
                      self.send_header('Content-Type', 'application/json')
                      self.end_headers()
                      self.wfile.write(json.dumps({'status': 'healthy', 'message': 'Bootstrapping complete. Ready for CI/CD deploy.'}).encode())
              HTTPServer(('0.0.0.0', 8000), Handler).serve_forever()
              "
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
  }
}
