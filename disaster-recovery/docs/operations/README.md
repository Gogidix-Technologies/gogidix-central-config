# Disaster Recovery - Operations Guide

## Overview

This document provides operational procedures, monitoring guidelines, and maintenance instructions for the Disaster Recovery service.

## Service Operations

### Service Management

#### Starting the Service

```bash
# Using systemd
sudo systemctl start disaster-recovery

# Using Docker
docker-compose -f docker-compose.prod.yml up -d disaster-recovery

# Using Kubernetes
kubectl apply -f k8s/deployment.yaml -n central-configuration
```

#### Stopping the Service

```bash
# Using systemd
sudo systemctl stop disaster-recovery

# Using Kubernetes
kubectl scale deployment disaster-recovery --replicas=0 -n central-configuration
```

### Health Checks

```bash
# Check service health
curl https://dr-service.exalt-social-ecommerce.com/actuator/health

# View service metrics
curl https://dr-service.exalt-social-ecommerce.com/actuator/metrics
```

## Monitoring and Alerting

### Key Performance Indicators

| Metric | Normal Range | Alert Threshold |
|--------|--------------|-----------------|
| Service Availability | > 99.9% | < 99.5% |
| Backup Success Rate | > 98% | < 95% |
| Recovery Time | < 1 hour | > 2 hours |

### Prometheus Metrics

```yaml
# Key metrics to monitor
- disaster_recovery_backup_total{status="success"}
- disaster_recovery_backup_duration_seconds
- disaster_recovery_restore_duration_seconds
- disaster_recovery_failover_total
```

## Backup Operations

### Manual Backup

```bash
# Trigger manual backup
curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/backups \
  -H "Content-Type: application/json" \
  -d '{"type": "FULL", "description": "Manual backup"}'

# List backups
curl https://dr-service.exalt-social-ecommerce.com/api/v1/backups/list
```

### Backup Verification

```bash
# Verify backup integrity
curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/backups/verify/{backupId}
```

## Restore Operations

### Restore Process

1. Identify the backup to restore
   ```bash
   curl https://dr-service.exalt-social-ecommerce.com/api/v1/backups/list
   ```

2. Validate backup integrity
   ```bash
   curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/backups/verify/{backupId}
   ```

3. Initiate restore process
   ```bash
   curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/restore \
     -H "Content-Type: application/json" \
     -d '{"backupId": "backup-2025-06-24", "services": ["all"], "priority": "high"}'
   ```

4. Monitor restore progress
   ```bash
   curl https://dr-service.exalt-social-ecommerce.com/api/v1/restore/status/{restoreId}
   ```

## Failover Management

### Regional Failover

```bash
# Check failover readiness
curl https://dr-service.exalt-social-ecommerce.com/api/v1/failover/readiness

# Initiate regional failover
curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/failover/execute \
  -H "Content-Type: application/json" \
  -d '{"targetRegion": "eu-west-2", "services": ["critical"]}'
```

## Troubleshooting

### Common Issues

#### Backup Failures

1. Check service logs
   ```bash
   kubectl logs -l app=disaster-recovery -n central-configuration
   ```

2. Verify storage connectivity
   ```bash
   curl https://dr-service.exalt-social-ecommerce.com/api/v1/storage/check
   ```

3. Check backup error details
   ```bash
   curl https://dr-service.exalt-social-ecommerce.com/api/v1/backups/{backupId}/errors
   ```

#### Restore Failures

1. Verify backup consistency
   ```bash
   curl -X POST https://dr-service.exalt-social-ecommerce.com/api/v1/backups/verify/{backupId}
   ```

2. Check resource availability
   ```bash
   kubectl describe nodes
   ```

## Maintenance Procedures

### Regular Maintenance

1. Daily: Review backup status and alerts
2. Weekly: Test backup verification
3. Monthly: Perform test restore in staging
4. Quarterly: Complete failover drill
