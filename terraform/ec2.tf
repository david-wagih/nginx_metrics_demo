# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Use provided AMI or default to latest Amazon Linux 2023
locals {
  ami_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
}

# User data script to install Docker, clone repo, and start services
locals {
  user_data = <<-EOF
#!/bin/bash
set -e

echo "=== User Data Started $$(date) ===" | tee -a /var/log/user-data.log

# Update system
dnf update -y

# Install Docker and Git
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# Install Docker Compose (standalone binary)
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
if [ -z "$$DOCKER_COMPOSE_VERSION" ]; then
    DOCKER_COMPOSE_VERSION="v2.24.0"
fi
curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Wait for Docker to be ready
sleep 5

# Create application directory
APP_DIR="/opt/nginx_metrics_demo"
mkdir -p $$APP_DIR
chown ec2-user:ec2-user $$APP_DIR

# Clone repository
echo "Cloning ${var.github_repo_url}"
sudo -u ec2-user git clone ${var.github_repo_url} $$APP_DIR

# Build nginx image first (using legacy builder to avoid buildx issues)
cd $$APP_DIR
docker build -t nginx_metrics_demo-nginx ./nginx

# Start all services
/usr/local/bin/docker-compose up -d

echo "=== Deployment Complete $$(date) ===" | tee -a /var/log/user-data.log
EOF
}


# EC2 Instance
resource "aws_instance" "nginx_metrics_demo" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.nginx_metrics_demo.key_name
  vpc_security_group_ids = [aws_security_group.nginx_metrics_demo.id]
  user_data_base64       = base64encode(local.user_data)

  # EBS volume configuration
  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    encrypted   = true
    
    tags = {
      Name        = "${var.project_name}-root-${var.environment}"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  # Enable public IP if requested
  associate_public_ip_address = var.enable_public_ip

  tags = {
    Name        = "${var.project_name}-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

