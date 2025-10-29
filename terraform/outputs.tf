output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.nginx_metrics_demo.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.nginx_metrics_demo.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.nginx_metrics_demo.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.nginx_metrics_demo.public_dns
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i nginx-metrics-demo-key.pem ec2-user@${aws_instance.nginx_metrics_demo.public_ip}"
}

output "private_key" {
  description = "Private key for SSH access (save this to a file)"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "private_key_filename" {
  description = "Suggested filename for the private key"
  value       = "nginx-metrics-demo-key.pem"
}

output "nginx_url" {
  description = "URL to access Nginx"
  value       = "http://${aws_instance.nginx_metrics_demo.public_ip}:8080"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.nginx_metrics_demo.public_ip}:9090"
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_instance.nginx_metrics_demo.public_ip}:3000"
}

output "grafana_credentials" {
  description = "Grafana login credentials"
  value       = "Username: admin | Password: admin"
  sensitive   = false
}

output "deployment_info" {
  description = "Deployment information"
  value = <<-EOT
    Nginx Metrics Demo Deployment
    
    Instance ID: ${aws_instance.nginx_metrics_demo.id}
    Public IP:   ${aws_instance.nginx_metrics_demo.public_ip}
    
    Services:
    - Nginx:     http://${aws_instance.nginx_metrics_demo.public_ip}:8080
    - Prometheus: http://${aws_instance.nginx_metrics_demo.public_ip}:9090
    - Grafana:   http://${aws_instance.nginx_metrics_demo.public_ip}:3000
    
    SSH Access:
    ssh -i nginx-metrics-demo-key.pem ec2-user@${aws_instance.nginx_metrics_demo.public_ip}
    
    Private Key:
    Save the private_key output to nginx-metrics-demo-key.pem:
    terraform output -raw private_key > nginx-metrics-demo-key.pem
    chmod 400 nginx-metrics-demo-key.pem
    
    Note: Services are automatically deployed from GitHub:
    ${var.github_repo_url}
    
    Stack should be running automatically after instance startup!
  EOT
}

