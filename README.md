# Nginx Metrics Demo

This demo showcases nginx metrics collection using nginx-prometheus-exporter and OpenTelemetry Collector.

## Architecture

```
┌─────────┐      ┌──────────────────┐      ┌─────────────┐
│  Nginx  │─────▶│ nginx-exporter   │─────▶│  Collector  │
│         │      │  (port 9113)      │      │             │
└─────────┘      └──────────────────┘      └──────┬──────┘
                                                   │
                                                   ▼
                                            ┌─────────────┐
                                            │ Debug       │
                                            │ Console     │
                                            └─────────────┘
```

## Components

1. **Nginx**: Web server with `stub_status` endpoint enabled
2. **nginx-prometheus-exporter**: Scrapes nginx metrics from `/stub_status` and exposes them in Prometheus format
3. **OpenTelemetry Collector**: 
   - Scrapes metrics from nginx-exporter using Prometheus receiver
   - Exports to debug console (stdout) for viewing
   - Exposes Prometheus endpoint at `:8889` for Prometheus scraping
4. **Prometheus**: Scrapes metrics from the OpenTelemetry Collector and stores them
5. **Grafana**: Visualization platform connected to Prometheus for creating dashboards

## Getting Started

1. Start all services:
```bash
docker-compose up -d
```

2. Generate some traffic to nginx:
```bash
# Make some requests
curl http://localhost:8080/
curl http://localhost:8080/stub_status
```

Or use a loop to generate continuous traffic:
```bash
while true; do curl -s http://localhost:8080/ > /dev/null; sleep 1; done
```

3. View metrics in collector debug console:
```bash
docker-compose logs -f collector
```

The debug exporter will show detailed metric information including:
- Nginx connection metrics
- Request metrics
- Response status codes
- Worker process information

4. Access Prometheus UI:
   - Open http://localhost:9090
   - Navigate to Status > Targets to verify scraping
   - Query metrics using PromQL in the Graph tab

5. Access Grafana UI:
   - Open http://localhost:3000
   - Login with: `admin` / `admin`
   - Prometheus datasource is automatically configured
   - Create dashboards to visualize nginx metrics

## Viewing Metrics

### Debug Console
Metrics are logged to the collector container's stdout:
```bash
docker-compose logs -f collector
```

### Prometheus UI
Access the Prometheus UI at http://localhost:9090 to:
- View metrics in real-time
- Write PromQL queries
- Check targets status
- Explore available metrics

### Grafana Dashboards
Access Grafana at http://localhost:3000 and:
- Create dashboards with the Prometheus datasource (already configured)
- Use queries like:
  - `nginx_connections_active` - Active connections
  - `nginx_http_requests_total` - Total requests
  - `rate(nginx_http_requests_total[5m])` - Request rate
  - `nginx_connections_reading`, `nginx_connections_writing`, `nginx_connections_waiting`

### Prometheus Metrics Endpoint
The collector exposes a Prometheus-compatible endpoint at:
```
http://localhost:8889/metrics
```

You can view it directly:
```bash
curl http://localhost:8889/metrics
```

## Available Metrics

The nginx-exporter provides metrics such as:
- `nginx_connections_active` - Active client connections
- `nginx_connections_reading` - Connections where nginx is reading request header
- `nginx_connections_writing` - Connections where nginx is writing response
- `nginx_connections_waiting` - Idle client connections waiting
- `nginx_http_requests_total` - Total number of client requests
- `nginx_up` - Status of the nginx server (1 = up, 0 = down)

## Creating Grafana Dashboards

Example PromQL queries for nginx metrics:

1. **Request Rate**:
   ```
   rate(nginx_http_requests_total[5m])
   ```

2. **Active Connections**:
   ```
   nginx_connections_active
   ```

3. **Connection States**:
   ```
   nginx_connections_reading
   nginx_connections_writing
   nginx_connections_waiting
   ```

4. **Nginx Status**:
   ```
   nginx_up
   ```

## Troubleshooting

1. **No metrics appearing**: 
   - Ensure nginx is receiving traffic
   - Check that `/stub_status` endpoint is accessible: `curl http://localhost:8080/stub_status`

2. **Exporter not scraping**:
   - Verify nginx-exporter can reach nginx: `docker-compose exec nginx-exporter wget -O- http://nginx:80/stub_status`

3. **Collector not receiving metrics**:
   - Check collector logs: `docker-compose logs collector`
   - Verify nginx-exporter metrics endpoint: `curl http://localhost:9113/metrics`

## Ports

- `8080`: Nginx web server
- `9113`: nginx-prometheus-exporter metrics endpoint
- `8889`: OpenTelemetry Collector Prometheus exporter endpoint
- `9090`: Prometheus UI
- `3000`: Grafana UI
- `4317`: OTLP gRPC receiver
- `4318`: OTLP HTTP receiver

