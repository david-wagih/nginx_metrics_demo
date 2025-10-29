# EC2 Deployment Guide

This guide outlines what changes (or doesn't change) when deploying the nginx metrics demo to an EC2 instance.

## What Stays the Same ✅

Most of your Docker Compose configuration works **as-is** on EC2:

1. **Service-to-service communication**: Internal Docker networking using service names (`nginx`, `prometheus`, `collector`, etc.) works the same way
2. **Docker Compose file**: No changes needed to the `docker-compose.yml` file
3. **Container configurations**: All internal container configurations remain the same
4. **Volume mounts**: Local volume mounts work the same way
5. **Grafana datasource**: The internal URL `http://prometheus:9090` works fine within Docker network

## What Needs Attention 🔧

### 1. AWS Security Groups

You need to configure security groups to allow inbound traffic on the exposed ports:

| Service | Port | Protocol | Access |
|---------|------|----------|--------|
| Nginx | 8080 | TCP | HTTP (or restrict to specific IPs) |
| Prometheus | 9090 | TCP | HTTP (or restrict to admin IPs) |
| Grafana | 3000 | TCP | HTTP (or restrict to admin IPs) |
| Collector | 8889 | TCP | Optional (for external scraping) |
| nginx-exporter | 9113 | TCP | Optional (usually internal only) |
| OTLP gRPC | 4317 | TCP | Optional (for external metric ingestion) |
| OTLP HTTP | 4318 | TCP | Optional (for external metric ingestion) |

**Security Group Rules Example:**
```
Inbound Rules:
- Port 8080: 0.0.0.0/0 (or restrict to your IP)
- Port 3000: Your Admin IP only (recommended)
- Port 9090: Your Admin IP only (recommended)
- Port 8889: Internal/VPC only (optional)
```

**⚠️ Security Recommendation**: Restrict Prometheus (9090) and Grafana (3000) to your IP address or VPN for security.

### 2. EC2 Instance Firewall (Optional but Recommended)

If your EC2 instance has a firewall enabled (like `ufw`), you may need to allow Docker traffic:

```bash
# Allow Docker bridge network (if needed)
sudo ufw allow from 172.17.0.0/16
```

### 3. EC2 Instance Type

Recommendations:
- **Minimum**: `t3.small` (2 vCPU, 2GB RAM)
- **Recommended**: `t3.medium` (2 vCPU, 4GB RAM) or `t3.large` (2 vCPU, 8GB RAM)
- For production: Consider `t3.xlarge` or dedicated instances

### 4. Storage Considerations

- EBS volume size: At least 20GB (recommended 50GB+)
- Prometheus will store time-series data, so plan for growth
- Monitor disk usage: `df -h`

### 5. Access URLs

Instead of `localhost`, use your EC2 instance:
- **Public IP**: `http://<EC2_PUBLIC_IP>:8080` (nginx)
- **Public IP**: `http://<EC2_PUBLIC_IP>:9090` (Prometheus)
- **Public IP**: `http://<EC2_PUBLIC_IP>:3000` (Grafana)

Or if using a domain:
- `http://your-domain.com:8080`
- `http://your-domain.com:9090`
- `http://your-domain.com:3000`

## Step-by-Step EC2 Deployment

### 1. Launch EC2 Instance

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ec2-user@<EC2_IP>
```

### 2. Install Prerequisites

```bash
# Install Docker
sudo yum update -y
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Log out and back in for group changes to take effect
exit
```

### 3. Transfer Files to EC2

```bash
# On your local machine
scp -i your-key.pem -r nginx_metrics_demo ec2-user@<EC2_IP>:~/
```

Or use Git:
```bash
# On EC2 instance
git clone <your-repo-url>
cd observability-playground/nginx_metrics_demo
```

### 4. Configure Security Groups

In AWS Console → EC2 → Security Groups:
- Add inbound rules for ports 8080, 3000, 9090 (and others as needed)
- Restrict admin ports (3000, 9090) to your IP for security

### 5. Start Services

```bash
cd nginx_metrics_demo
docker compose up -d
```

### 6. Verify Services

```bash
# Check all containers are running
docker compose ps

# Check logs
docker compose logs -f

# Verify services are accessible
curl http://localhost:8080/stub_status
curl http://localhost:9090/api/v1/status/config
curl http://localhost:3000/api/health
```

### 7. Access from Your Machine

- Nginx: `http://<EC2_PUBLIC_IP>:8080`
- Prometheus: `http://<EC2_PUBLIC_IP>:9090`
- Grafana: `http://<EC2_PUBLIC_IP>:3000` (admin/admin)

## Security Enhancements (Optional)

### 1. Use Nginx Reverse Proxy

For production, consider putting Nginx in front of Prometheus and Grafana:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location /prometheus {
        proxy_pass http://localhost:9090;
    }
    
    location /grafana {
        proxy_pass http://localhost:3000;
    }
}
```

### 2. Enable HTTPS

Use Let's Encrypt or AWS Certificate Manager for SSL/TLS certificates.

### 3. Authentication

- **Grafana**: Already has login (admin/admin) - change default password!
- **Prometheus**: Consider using Nginx Basic Auth or Prometheus authentication

### 4. Network Restrictions

- Use AWS Security Groups to restrict access
- Consider using VPN or bastion host for admin access
- Only expose port 8080 (nginx) publicly if needed

## Monitoring EC2 Resources

Monitor your EC2 instance health:

```bash
# Disk usage
df -h

# Memory usage
free -h

# Docker resource usage
docker stats

# System load
top
htop  # if installed
```

## Troubleshooting

### Cannot Access Services from Outside EC2

1. **Check Security Groups**: Ensure ports are open in AWS Security Groups
2. **Check EC2 Firewall**: Verify firewall rules if enabled
3. **Check Container Status**: `docker compose ps`
4. **Check Logs**: `docker compose logs <service-name>`

### High Memory Usage

- Increase instance size
- Adjust Prometheus retention: `--storage.tsdb.retention.time=7d`
- Clean up old data periodically

### Disk Space Issues

- Monitor Prometheus data growth
- Set retention policies
- Consider EBS volume expansion

## Production Considerations

1. **Use ECS/EKS**: For production, consider AWS ECS or EKS instead of direct EC2
2. **ALB/NLB**: Use Application/Network Load Balancer for high availability
3. **CloudWatch Integration**: Send metrics to CloudWatch for monitoring
4. **Backup**: Regular backups of Grafana dashboards and Prometheus data
5. **Auto-scaling**: Consider auto-scaling groups for high availability
6. **SSL/TLS**: Always use HTTPS in production
7. **IAM Roles**: Use IAM roles for EC2 instead of access keys
8. **VPC**: Use VPC with private subnets for better security

## Quick Reference: Ports and Access

| Component | Internal Docker Network | External Access |
|-----------|------------------------|-----------------|
| nginx | `nginx:80` | `http://<EC2_IP>:8080` |
| Prometheus | `prometheus:9090` | `http://<EC2_IP>:9090` |
| Grafana | `grafana:3000` | `http://<EC2_IP>:3000` |
| Collector | `collector:8889` | `http://<EC2_IP>:8889` (optional) |
| nginx-exporter | `nginx-exporter:9113` | `http://<EC2_IP>:9113` (optional) |

## Summary

**Most things work the same!** The main differences are:
1. ✅ Configure AWS Security Groups for inbound traffic
2. ✅ Use EC2 IP/domain instead of `localhost`
3. ⚠️ Consider security (restrict admin ports, use HTTPS)
4. 💾 Monitor storage and resources
5. 🔒 Change default passwords

Your Docker Compose setup is cloud-ready with minimal changes!

