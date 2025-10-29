# Terraform Configuration for Nginx Metrics Demo

This Terraform configuration provisions an EC2 instance with all the necessary security groups and setup to run the nginx metrics demo stack.

## Prerequisites

1. **AWS Account** with appropriate permissions
2. **AWS CLI** configured with credentials
3. **Terraform** >= 1.0 installed
4. **AWS Key Pair** created in your AWS region (for SSH access)

## Quick Start

### 1. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and update:
- `key_name`: Your AWS key pair name
- `allowed_admin_cidr`: Your IP address in CIDR format (e.g., "203.0.113.0/32") for security
- `aws_region`: Your preferred AWS region

**Security Note**: For development, `0.0.0.0/0` works but is insecure. For production, restrict `allowed_admin_cidr` to your specific IP.

### 2. Initialize Terraform

```bash
cd terraform
terraform init
```

### 3. Review Plan

```bash
terraform plan
```

This will show you what resources will be created:
- EC2 instance (t3.medium for development)
- Security group with required ports
- EBS volume (30GB for development)

### 4. Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will create:
- Security group with ports: 22 (SSH), 8080 (Nginx), 9090 (Prometheus), 3000 (Grafana)
- EC2 instance with Docker and Docker Compose pre-installed

### 5. Deploy Application

After Terraform completes, you'll see output with SSH command and URLs:

```bash
# SSH into the instance
ssh -i <your-key.pem> ec2-user@<instance-public-ip>

# Once connected, copy your application files
# Option 1: Using SCP (from your local machine)
scp -i <your-key.pem> -r ../nginx_metrics_demo ec2-user@<instance-public-ip>:/opt/

# Option 2: Using Git (on the EC2 instance)
cd /opt
sudo git clone <your-repo-url>
cd observability-playground/nginx_metrics_demo

# Note: Docker group changes require re-login
# Run this or log out and back in:
newgrp docker

# Start the stack
docker compose up -d

# Verify services
docker compose ps
docker compose logs -f
```

## Configuration

### Instance Type

Default: `t3.medium` (2 vCPU, 4GB RAM)

For development, this is sufficient. To change:
- Update `instance_type` in `terraform.tfvars`
- Options: `t3.small` (2GB RAM), `t3.medium` (4GB RAM), `t3.large` (8GB RAM)

### Security Groups

The security group allows:
- **Port 22**: SSH from anywhere (restrict in production)
- **Port 8080**: Nginx (public access by default)
- **Port 9090**: Prometheus (restricted by `allowed_admin_cidr`)
- **Port 3000**: Grafana (restricted by `allowed_admin_cidr`)
- **Port 8889**: Collector Prometheus exporter (restricted)
- **Port 9113**: Nginx exporter (restricted)
- **Ports 4317, 4318**: OTLP receivers (restricted)

### Volume Size

Default: 30GB (GP3)

Prometheus stores time-series data, so monitor usage. You can resize later or increase `volume_size` in variables.

## Outputs

After applying, Terraform will output:

- Instance ID and IP addresses
- SSH command
- Service URLs (Nginx, Prometheus, Grafana)
- Deployment instructions

Access the URLs in your browser:
- Nginx: `http://<instance-ip>:8080`
- Prometheus: `http://<instance-ip>:9090`
- Grafana: `http://<instance-ip>:3000` (admin/admin)

## Terraform Commands

### View Current State
```bash
terraform show
```

### View Outputs
```bash
terraform output
```

### Update Configuration
```bash
# Edit variables or configuration files
terraform plan
terraform apply
```

### Destroy Resources
```bash
terraform destroy
```

**Warning**: This will delete all resources including the EC2 instance and all data!

## Security Best Practices

1. **Restrict Admin Ports**: Update `allowed_admin_cidr` to your IP:
   ```
   allowed_admin_cidr = "YOUR.IP.ADDRESS/32"
   ```

2. **Use SSH Keys**: Never share your private key file

3. **Change Default Passwords**: Change Grafana admin password after first login

4. **Use IAM Roles**: For production, use IAM roles instead of access keys

5. **Enable MFA**: Use MFA for AWS console access

6. **Monitor Access**: Review CloudTrail logs regularly

## Troubleshooting

### Cannot SSH into Instance

1. Verify security group allows port 22
2. Check key pair name matches `key_name` variable
3. Verify instance has public IP (if using public access)
4. Check AWS region matches your key pair region

### Cannot Access Services

1. Verify security groups allow required ports
2. Check service is running: `docker compose ps`
3. Check logs: `docker compose logs <service-name>`
4. Verify instance firewall (usually not an issue with security groups)

### High Costs

- Use `t3.small` instead of `t3.medium` for testing
- Stop the instance when not in use
- Use spot instances for development (modify `ec2.tf`)
- Monitor CloudWatch for unexpected usage

### Docker Permission Denied

After SSH, you may need to activate the docker group:
```bash
newgrp docker
# or logout and login again
```

## Cost Estimation (Development)

Approximate monthly costs for eu-central-1:

- **t3.medium instance**: ~$30/month (on-demand)
- **30GB EBS gp3 storage**: ~$3/month
- **Data transfer**: Varies by usage

**Total**: ~$33-40/month for 24/7 operation

**Cost Saving**: Stop instance when not in use:
```bash
# Stop instance
aws ec2 stop-instances --instance-ids <instance-id>

# Start instance
aws ec2 start-instances --instance-ids <instance-id>
```

## Customization

### Use Different AMI

Update `ami_id` in `terraform.tfvars`:
```hcl
ami_id = "ami-xxxxxxxxxxxxxxxxx"
```

### Add EBS Volume

Add to `ec2.tf`:
```hcl
resource "aws_ebs_volume" "data" {
  availability_zone = aws_instance.nginx_metrics_demo.availability_zone
  size              = 50
  type              = "gp3"
  encrypted         = true
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.nginx_metrics_demo.id
}
```

### Use Existing VPC

Modify `security_groups.tf` to reference specific VPC:
```hcl
data "aws_vpc" "custom" {
  id = "vpc-xxxxxxxxx"
}
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS EC2 Pricing](https://aws.amazon.com/ec2/pricing/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## Support

For issues related to:
- **Terraform configuration**: Check Terraform documentation
- **Docker Compose stack**: See main README.md
- **AWS services**: Check AWS documentation

