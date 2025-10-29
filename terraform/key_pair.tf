# Generate private key
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create AWS key pair from public key
resource "aws_key_pair" "nginx_metrics_demo" {
  key_name   = "${var.project_name}-${var.environment}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh

  tags = {
    Name        = "${var.project_name}-${var.environment}-key"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

