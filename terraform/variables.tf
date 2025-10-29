variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type for development"
  type        = string
  default     = "t3.medium" # 2 vCPU, 4GB RAM - suitable for development
}

variable "key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
}

variable "allowed_admin_cidr" {
  description = "CIDR block allowed to access admin ports (Prometheus, Grafana). Use your IP/32 for security."
  type        = string
  default     = "0.0.0.0/0" # WARNING: For development only! Restrict in production.
}

variable "allowed_nginx_cidr" {
  description = "CIDR block allowed to access nginx (port 8080)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "nginx-metrics-demo"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "volume_size" {
  description = "EBS volume size in GB"
  type        = number
  default     = 30 # Development size
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance. Leave empty to use latest Amazon Linux 2023"
  type        = string
  default     = ""
}

variable "enable_public_ip" {
  description = "Enable public IP for the EC2 instance"
  type        = bool
  default     = true
}

