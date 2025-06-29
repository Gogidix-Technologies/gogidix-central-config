# Disaster Recovery Service - Setup Guide

## Overview

This document provides comprehensive setup instructions for the Disaster Recovery service, including local development environment configuration, backup system integration, and cross-region failover setup.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Environment Configuration](#environment-configuration)
4. [Backup Systems Integration](#backup-systems-integration)
5. [Verification and Testing](#verification-and-testing)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- **Memory**: Minimum 8GB RAM (16GB recommended)
- **Storage**: Minimum 20GB free space
- **Network**: Stable internet connection with access to cloud provider networks

### Required Software

```bash
# Java Development Kit
Java JDK 17+

# Build Tools
Maven 3.8+
Gradle 7.4+ (optional)

# Cloud Provider CLI Tools
AWS CLI 2.7+
Azure CLI 2.30+ (if using Azure)
Google Cloud SDK 390+ (if using GCP)

# Container Tools
Docker 20.10+
Docker Compose 2.3+

# Database Tools
PostgreSQL 14+ client
MongoDB 5.0+ client (optional)

# Monitoring Tools
Prometheus CLI
Grafana CLI
```

### Access Requirements

- AWS IAM credentials with appropriate permissions
- Cloud storage access credentials
- Backup storage system access
- CI/CD pipeline access (Jenkins/GitHub Actions)

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/disaster-recovery
```

### 2. Configure Environment Variables

Create a `.env` file in the project root based on the template:

```bash
cp .env.template .env
```

Edit the `.env` file with required configurations:

```
# Core Configuration
DR_SERVICE_PORT=8560
DR_SERVICE_HOST=localhost
SPRING_PROFILES_ACTIVE=dev

# AWS Configuration
AWS_REGION=eu-west-1
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key

# Database Backup Configuration
DB_BACKUP_RETENTION_DAYS=30
DB_BACKUP_SCHEDULE="0 2 * * *"
DB_BACKUP_ENCRYPTION_KEY=your-encryption-key

# Storage Configuration
S3_BACKUP_BUCKET=exalt-backup-dev
S3_BACKUP_PATH=disaster-recovery

# Notification Configuration
NOTIFICATION_EMAIL=devops@exalt-social-ecommerce.com
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/your-webhook-url
```

### 3. Build the Service

```bash
# Using Maven
mvn clean install

# Using Gradle (if applicable)
gradle clean build
```

### 4. Run Locally

```bash
# Using Maven
mvn spring-boot:run

# Using Docker
docker-compose -f docker-compose.dev.yml up
```

### 5. Verify Installation

```bash
# Check service health
curl http://localhost:8560/actuator/health

# Check service information
curl http://localhost:8560/actuator/info
```

## Environment Configuration

### Development Environment

```yaml
# application-dev.yml
spring:
  application:
    name: disaster-recovery-service
  datasource:
    url: jdbc:postgresql://localhost:5432/disaster_recovery_dev
    username: dev_user
    password: dev_password
    
disaster-recovery:
  mode: development
  backup:
    enabled: true
    mock: true
    schedule: "0 */30 * * * *"
  restore:
    auto-validate: true
```

### Testing Environment

```yaml
# application-test.yml
spring:
  application:
    name: disaster-recovery-service
  datasource:
    url: jdbc:postgresql://test-db:5432/disaster_recovery_test
    username: test_user
    password: test_password
    
disaster-recovery:
  mode: testing
  backup:
    enabled: true
    mock: false
    schedule: "0 0 */2 * * *"
  restore:
    auto-validate: true
```

### Production Environment

```yaml
# application-prod.yml
spring:
  application:
    name: disaster-recovery-service
  datasource:
    url: jdbc:postgresql://prod-db.exalt-social-ecommerce.com:5432/disaster_recovery_prod
    username: ${DB_PROD_USER}
    password: ${DB_PROD_PASSWORD}
    
disaster-recovery:
  mode: production
  backup:
    enabled: true
    mock: false
    schedule: "0 0 2 * * *"
    retention-days: 90
  restore:
    auto-validate: true
    require-approval: true
    approval-timeout-minutes: 60
```

## Backup Systems Integration

### AWS S3 Integration

1. Create an AWS S3 bucket for backups:

```bash
aws s3 mb s3://exalt-disaster-recovery-backups
```

2. Configure bucket policies:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/disaster-recovery-role"
      },
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::exalt-disaster-recovery-backups",
        "arn:aws:s3:::exalt-disaster-recovery-backups/*"
      ]
    }
  ]
}
```

### Cross-Region Replication

1. Enable cross-region replication in your S3 bucket:

```bash
aws s3api put-bucket-replication --bucket exalt-disaster-recovery-backups --replication-configuration file://replication-config.json
```

2. Create the replication configuration file (`replication-config.json`):

```json
{
  "Role": "arn:aws:iam::123456789012:role/replication-role",
  "Rules": [
    {
      "Status": "Enabled",
      "Priority": 1,
      "DeleteMarkerReplication": { "Status": "Disabled" },
      "Filter": {},
      "Destination": {
        "Bucket": "arn:aws:s3:::exalt-disaster-recovery-backups-replica",
        "StorageClass": "STANDARD"
      }
    }
  ]
}
```

## Verification and Testing

### Backup Verification

```bash
# Manually trigger a backup
curl -X POST http://localhost:8560/api/backups/trigger \
  -H "Content-Type: application/json" \
  -d '{"type": "FULL", "description": "Manual test backup"}'

# List recent backups
curl http://localhost:8560/api/backups/list?limit=5

# Verify backup integrity
curl -X POST http://localhost:8560/api/backups/verify/latest
```

### Restore Testing

```bash
# Test restore process (dry run)
curl -X POST http://localhost:8560/api/restore/dry-run \
  -H "Content-Type: application/json" \
  -d '{"backupId": "backup-2023-10-15-020000", "targetEnvironment": "dev"}'

# Perform restore validation
curl -X POST http://localhost:8560/api/restore/validate \
  -H "Content-Type: application/json" \
  -d '{"backupId": "backup-2023-10-15-020000"}'
```

### Failover Testing

```bash
# Test failover readiness
curl -X GET http://localhost:8560/api/failover/status

# Simulate failover
curl -X POST http://localhost:8560/api/failover/simulate \
  -H "Content-Type: application/json" \
  -d '{"region": "eu-central-1", "services": ["api-gateway", "auth-service"]}'
```

## Troubleshooting

### Common Issues

#### Backup Failures

Problem: Scheduled backups are failing with permission errors

Solution:
1. Check IAM permissions:
   ```bash
   aws iam get-role --role-name disaster-recovery-role
   ```
2. Verify S3 bucket permissions:
   ```bash
   aws s3api get-bucket-policy --bucket exalt-disaster-recovery-backups
   ```
3. Check service logs:
   ```bash
   tail -f /var/log/disaster-recovery/backup.log
   ```

#### Database Connection Issues

Problem: Cannot connect to database during backup process

Solution:
1. Verify database connectivity:
   ```bash
   psql -h db-host -U backup-user -d database_name -c "SELECT 1"
   ```
2. Check network access between service and database
3. Review database user permissions:
   ```sql
   GRANT CONNECT ON DATABASE database_name TO backup_user;
   GRANT SELECT ON ALL TABLES IN SCHEMA public TO backup_user;
   ```

#### Restore Validation Failures

Problem: Restore validation fails with data integrity issues

Solution:
1. Verify backup integrity:
   ```bash
   curl -X POST http://localhost:8560/api/backups/verify/{backupId}
   ```
2. Check backup log for corruption warnings:
   ```bash
   grep "WARNING" /var/log/disaster-recovery/backup-{backupId}.log
   ```
3. Try restoring to an isolated environment for detailed testing

If issues persist, contact the platform engineering team at platform-support@exalt-social-ecommerce.com.
