# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group for nginx metrics demo
resource "aws_security_group" "nginx_metrics_demo" {
  name        = "${var.project_name}-sg-${var.environment}"
  description = "Security group for nginx metrics demo stack"
  vpc_id      = data.aws_vpc.default.id

  # SSH access
  ingress {
    description = "SSH from anywhere (restrict in production)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nginx (public access)
  ingress {
    description = "Nginx web server"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.allowed_nginx_cidr]
  }

  # Prometheus (admin access - should be restricted)
  ingress {
    description = "Prometheus UI (admin access)"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # Grafana (admin access - should be restricted)
  ingress {
    description = "Grafana UI (admin access)"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # Collector Prometheus exporter (optional - for external scraping)
  ingress {
    description = "OTEL Collector Prometheus exporter"
    from_port   = 8889
    to_port     = 8889
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # Nginx exporter (optional - usually internal only)
  ingress {
    description = "Nginx Prometheus Exporter"
    from_port   = 9113
    to_port     = 9113
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # OTLP gRPC receiver (optional - for external metric ingestion)
  ingress {
    description = "OTLP gRPC receiver"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # OTLP HTTP receiver (optional - for external metric ingestion)
  ingress {
    description = "OTLP HTTP receiver"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = [var.allowed_admin_cidr]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-sg-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
  }
}

