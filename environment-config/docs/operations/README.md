# Environment Config - Operations Guide

## Overview

This document provides operational procedures, monitoring guidelines, and maintenance instructions for the Environment Config service in production environments.

## Table of Contents

1. [Service Operations](#service-operations)
2. [Monitoring and Alerting](#monitoring-and-alerting)
3. [Configuration Management](#configuration-management)
4. [Security Operations](#security-operations)
5. [Troubleshooting](#troubleshooting)
6. [Maintenance Procedures](#maintenance-procedures)

## Service Operations

### Service Management

#### Starting the Service

```bash
# Using systemd
sudo systemctl start environment-config

# Using Docker
docker-compose -f docker-compose.prod.yml up -d

# Using Kubernetes
kubectl apply -f k8s/deployment.yaml -n central-configuration
```

#### Stopping the Service

```bash
# Graceful shutdown
sudo systemctl stop environment-config

# Force stop if needed
sudo systemctl kill environment-config

# Using Kubernetes
kubectl scale deployment environment-config --replicas=0 -n central-configuration
```

#### Service Status Checks

```bash
# Check service status
curl -s http://localhost:8540/actuator/health | jq

# Detailed health check
curl -s http://localhost:8540/actuator/health | jq

# Check service info
curl -s http://localhost:8540/actuator/info | jq
```

### Configuration Refresh

```bash
# Refresh configuration for a specific service
curl -X POST http://environment-config:8540/actuator/refresh \
  -H "Content-Type: application/json" \
  -d '{"services": ["service-name"]}'

# Refresh all services
curl -X POST http://environment-config:8540/actuator/bus-refresh
```

## Monitoring and Alerting

### Key Performance Indicators

| Metric | Normal Range | Warning | Critical |
|--------|--------------|---------|-----------|
| Uptime | 99.99% | < 99.9% | < 99.5% |
| Response Time | < 100ms | > 200ms | > 500ms |
| Config Requests | N/A | > 1000/min | > 5000/min |
| Error Rate | < 0.1% | > 1% | > 5% |
| Memory Usage | < 70% | > 85% | > 95% |

### Prometheus Metrics

```yaml
# Example Prometheus configuration
scrape_configs:
  - job_name: 'environment-config'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['environment-config:8540']
```

### Alert Rules

```yaml
groups:
- name: environment-config
  rules:
  - alert: ConfigServerDown
    expr: up{job="environment-config"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Environment Config Service is down"
      description: "The Environment Config Service has been down for more than 5 minutes"

  - alert: HighErrorRate
    expr: rate(http_server_requests_seconds_count{status=~"5.."}[5m]) / rate(http_server_requests_seconds_count[5m]) > 0.01
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High error rate on Environment Config Service"
      description: "Error rate is {{ $value }}%"
```

## Configuration Management

### Managing Configurations

#### List Available Configurations

```bash
# List all available configurations
curl -s http://environment-config:8540/actuator/env | jq

# Get specific configuration
curl -s http://environment-config:8540/actuator/env/spring.cloud.config.server.git.uri | jq
```

#### Update Configuration

1. Update the configuration in the Git repository
2. Refresh the configuration:
   ```bash
   # For a specific service
   curl -X POST http://environment-config:8540/actuator/refresh \
     -H "Content-Type: application/json" \
     -d '{"services": ["target-service"]}'
   
   # For all services
   curl -X POST http://environment-config:8540/actuator/bus-refresh
   ```

### Encryption and Decryption

```bash
# Encrypt a value
curl -X POST http://environment-config:8540/encrypt \
  -d 'sensitive-value' \
  -H "Content-Type: text/plain"

# Decrypt a value
curl -X POST http://environment-config:8540/decrypt \
  -d 'encrypted-value' \
  -H "Content-Type: text/plain"
```

## Security Operations

### Authentication and Authorization

```yaml
# Example security configuration
spring:
  security:
    user:
      name: admin
      password: ${CONFIG_SERVER_PASSWORD}
      roles: ADMIN
```

### Audit Logging

Audit logs are available at:
- `/var/log/environment-config/audit.log`
- Standard output (when running in containers)

## Troubleshooting

### Common Issues

#### Configuration Not Updating

1. Check if the configuration was pushed to the correct branch
2. Verify the refresh endpoint was called
3. Check service logs for errors

```bash
# Check service logs
journalctl -u environment-config -f

# Check Kubernetes logs
kubectl logs -l app=environment-config -n central-configuration
```

#### High Memory Usage

1. Check current memory usage:
   ```bash
   curl -s http://localhost:8540/actuator/metrics/jvm.memory.used | jq
   ```

2. Generate heap dump (if needed):
   ```bash
   curl -X POST http://localhost:8540/actuator/heapdump
   ```

## Maintenance Procedures

### Regular Maintenance

1. **Daily**:
   - Review error logs
   - Check disk space
   - Verify backup status

2. **Weekly**:
   - Rotate logs
   - Review metrics and alerting
   - Check for configuration drift

3. **Monthly**:
   - Review and update dependencies
   - Perform security audit
   - Test disaster recovery procedures

### Backup and Restore

#### Backup Procedure

```bash
# Backup configuration repository
BACKUP_DIR=/backup/config-$(date +%Y%m%d)
mkdir -p $BACKUP_DIR
rsync -av /path/to/config/repo $BACKUP_DIR/

# Backup encryption keys
cp /path/to/encrypt/keystore.jks $BACKUP_DIR/
```

#### Restore Procedure

```bash
# Restore from backup
rsync -av /backup/config-YYYYMMDD/repo/ /path/to/config/repo/

# Restart service to apply changes
sudo systemctl restart environment-config
```

### Version Upgrades

1. Review release notes for breaking changes
2. Test in staging environment
3. Create backup before upgrading production
4. Follow rolling update strategy in Kubernetes

## Disaster Recovery

### Recovery Procedures

1. **Service Outage**:
   - Check service status: `systemctl status environment-config`
   - Review logs: `journalctl -u environment-config -n 100 --no-pager`
   - Restart service if needed: `systemctl restart environment-config`

2. **Data Corruption**:
   - Restore from last known good backup
   - Verify configuration integrity
   - Roll forward any missing changes
