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
    
    # Update system
    sudo dnf update -y
    
    # Install Docker
    sudo dnf install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
    
    # Install Docker Compose
    DOCKER_COMPOSE_VERSION=$$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    sudo curl -L "https://github.com/docker/compose/releases/download/$${DOCKER_COMPOSE_VERSION}/docker-compose-$$(uname -s)-$$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Install Git (if not already installed)
    sudo dnf install -y git
    
    # Create application directory
    APP_DIR="/opt/nginx_metrics_demo"
    mkdir -p $$APP_DIR
    chown ec2-user:ec2-user $$APP_DIR
    
    # Clone the repository
    cd $$APP_DIR
    sudo -u ec2-user git clone ${var.github_repo_url} .
    
    # Activate docker group for current session
    # Note: This requires the script to run as root, but we need to use docker as ec2-user
    # We'll handle this by using sudo for docker commands or newgrp
    
    # Wait a moment for git clone to complete
    sleep 5
    
    # Change ownership of cloned files
    chown -R ec2-user:ec2-user $$APP_DIR
    
    # Start Docker Compose services as ec2-user
    # Use runuser to run as ec2-user with docker group access
    cd $$APP_DIR
    
    # Start services (using runuser to execute as ec2-user with proper group context)
    runuser -l ec2-user -c "cd $$APP_DIR && /usr/local/bin/docker-compose up -d"
    
    # Log completion
    echo "Nginx Metrics Demo deployed successfully!" > /tmp/deployment-status.txt
    echo "Repository: ${var.github_repo_url}" >> /tmp/deployment-status.txt
    echo "Deployment time: $$(date)" >> /tmp/deployment-status.txt
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

