# Post-Terraform Deployment Steps

After successfully applying the Terraform configuration, follow these steps to deploy the nginx metrics demo stack.

## Step 1: Get Instance Information

After `terraform apply` completes, you'll see output with:
- Instance public IP
- SSH command
- Service URLs

View outputs anytime with:
```bash
terraform output
```

Note the `instance_public_ip` from the output.

## Step 2: SSH into the Instance

```bash
ssh -i <path-to-your-key.pem> ec2-user@<instance-public-ip>
```

Replace:
- `<path-to-your-key.pem>` with your AWS key pair file path
- `<instance-public-ip>` with the IP from `terraform output`

Example:
```bash
ssh -i ~/.ssh/my-key.pem ec2-user@54.123.45.67
```

## Step 3: Activate Docker Group

After SSH, you need to activate the docker group (Docker was installed in user_data):

```bash
newgrp docker
```

Or logout and login again to activate the group permanently.

Verify Docker is working:
```bash
docker --version
docker compose version
```

## Step 4: Transfer Application Files

You have two options to get the nginx_metrics_demo files on the instance:

### Option A: Using SCP (from your local machine)

From your **local machine** (not on EC2), run:

```bash
# Navigate to the parent directory of nginx_metrics_demo
cd /Users/david.wageh/Development/Devops-Repos/observability-playground

# Copy the entire nginx_metrics_demo directory
scp -i <path-to-your-key.pem> -r nginx_metrics_demo ec2-user@<instance-public-ip>:/opt/
```

This copies everything to `/opt/nginx_metrics_demo` on the EC2 instance.

### Option B: Using Git (on the EC2 instance)

If your code is in a Git repository:

```bash
# On EC2 instance
sudo dnf install -y git  # If not already installed
cd /opt
sudo git clone <your-repo-url>
cd observability-playground/nginx_metrics_demo
```

### Option C: Manual Copy (for small changes)

If you just need to copy specific files:

```bash
# From local machine
scp -i <path-to-your-key.pem> -r nginx_metrics_demo/docker-compose.yml ec2-user@<instance-ip>:/opt/nginx_metrics_demo/
scp -i <path-to-your-key.pem> -r nginx_metrics_demo/nginx ec2-user@<instance-ip>:/opt/nginx_metrics_demo/
# ... repeat for other directories/files
```

## Step 5: Start the Stack

SSH back into the instance (if you logged out) and navigate to the application:

```bash
# SSH into instance
ssh -i <path-to-your-key.pem> ec2-user@<instance-public-ip>

# Navigate to application directory
cd /opt/nginx_metrics_demo

# Verify files are present
ls -la

# Start all services
docker compose up -d
```

## Step 6: Verify Services

Check that all containers are running:

```bash
docker compose ps
```

You should see:
- nginx
- nginx-exporter
- collector
- prometheus
- grafana

All should show "Up" status.

## Step 7: Check Logs

View logs to ensure everything started correctly:

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f collector
docker compose logs -f nginx
```

## Step 8: Generate Test Traffic

Generate some traffic to see metrics:

```bash
# On EC2 instance or locally
while true; do curl -s http://localhost:8080/ > /dev/null; sleep 1; done
```

Or from your local machine:
```bash
while true; do curl -s http://<instance-public-ip>:8080/ > /dev/null; sleep 1; done
```

## Step 9: Access Services

Use your browser to access:

1. **Nginx**: `http://<instance-public-ip>:8080`
   - You should see the default nginx welcome page
   - Check metrics: `http://<instance-public-ip>:8080/stub_status`

2. **Prometheus**: `http://<instance-public-ip>:9090`
   - Go to Status > Targets to verify scraping is working
   - Use Graph tab to query metrics like:
     - `nginx_connections_active`
     - `nginx_http_requests_total`
     - `rate(nginx_http_requests_total[5m])`

3. **Grafana**: `http://<instance-public-ip>:3000`
   - Login: `admin` / `admin`
   - Prometheus datasource is already configured
   - Go to Dashboards > New Dashboard
   - Add a panel and query: `nginx_connections_active`

4. **Collector Debug Logs**: View metrics in terminal
   ```bash
   docker compose logs -f collector
   ```

## Step 10: Create Grafana Dashboard

1. Go to Grafana: `http://<instance-public-ip>:3000`
2. Login with `admin` / `admin`
3. Click **Dashboards** > **New Dashboard**
4. Add a new panel
5. Use Prometheus as data source (already configured)
6. Try these queries:

**Connection Metrics Panel:**
```
nginx_connections_active
nginx_connections_reading
nginx_connections_writing
nginx_connections_waiting
```

**Request Rate Panel:**
```
rate(nginx_http_requests_total[5m])
```

**Total Requests Panel:**
```
nginx_http_requests_total
```

## Troubleshooting

### Cannot SSH into Instance
- Verify security group allows port 22
- Check key file permissions: `chmod 400 <your-key.pem>`
- Verify key pair name matches `key_name` in terraform.tfvars

### Docker Permission Denied
- Run: `newgrp docker` or logout/login
- Or use: `sudo docker compose up -d`

### Services Not Starting
- Check logs: `docker compose logs <service-name>`
- Verify files are copied correctly
- Check disk space: `df -h`

### Cannot Access Services from Browser
- Verify security groups allow required ports
- Check service is running: `docker compose ps`
- Try accessing from instance itself: `curl http://localhost:8080`

### No Metrics in Prometheus
- Ensure nginx is receiving traffic
- Check collector logs: `docker compose logs collector`
- Verify Prometheus target is UP: http://<instance-ip>:9090/targets

## Quick Reference Commands

```bash
# View all services
docker compose ps

# View logs
docker compose logs -f

# Restart services
docker compose restart

# Stop services
docker compose down

# Start services
docker compose up -d

# Rebuild and start
docker compose up -d --build

# View resource usage
docker stats

# SSH access
ssh -i <key.pem> ec2-user@<instance-ip>

# View Terraform outputs
terraform output
```

## Next Steps After Deployment

1. **Change Grafana Password**: After first login, change default password
2. **Create Dashboards**: Build custom dashboards for your metrics
3. **Set Up Alerts**: Configure Grafana alerting
4. **Monitor Resources**: Keep an eye on EC2 instance CPU, memory, disk
5. **Set Up Backups**: Backup Grafana dashboards and Prometheus data

---

**🎉 Congratulations!** Your nginx metrics demo stack is now running on EC2!

