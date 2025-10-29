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

# User data script to install Docker and Docker Compose
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
    mkdir -p /opt/nginx-metrics-demo
    chown ec2-user:ec2-user /opt/nginx-metrics-demo
    
    # Note: Docker Compose group changes require logout/login
    # The user will need to SSH in again or use 'newgrp docker' to activate group changes
    
    # Create a simple message file
    echo "Docker and Docker Compose installation completed!" > /opt/nginx-metrics-demo/README.txt
    echo "Please SSH in again or run 'newgrp docker' to use docker commands without sudo" >> /opt/nginx-metrics-demo/README.txt
    echo "" >> /opt/nginx-metrics-demo/README.txt
    echo "To deploy:" >> /opt/nginx-metrics-demo/README.txt
    echo "1. Copy your nginx_metrics_demo directory to /opt/nginx-metrics-demo" >> /opt/nginx-metrics-demo/README.txt
    echo "2. cd /opt/nginx-metrics-demo" >> /opt/nginx-metrics-demo/README.txt
    echo "3. docker compose up -d" >> /opt/nginx-metrics-demo/README.txt
  EOF
}

# EC2 Instance
resource "aws_instance" "nginx_metrics_demo" {
  ami                    = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
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

