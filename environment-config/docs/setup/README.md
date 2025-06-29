# Environment Config - Setup Guide

## Overview

This document provides setup instructions for the Environment Config service, which manages environment-specific configurations across the Social E-commerce Ecosystem.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Configuration Structure](#configuration-structure)
4. [Environment Integration](#environment-integration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 2GB free space
- **Network**: Access to Git repository and required services

### Required Software

```bash
# Core Dependencies
Java JDK 17+
Maven 3.8+
Git 2.30+

# Container Support (Optional)
Docker 20.10+
Docker Compose 2.3+

# Recommended Tools
jq 1.6+ (for JSON processing)
```

### Access Requirements

- Read access to configuration repository
- Environment-specific credentials
- Network access to dependent services

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/environment-config
```

### 2. Configure Environment

Create a `.env` file from the template:

```bash
cp .env.template .env
```

Edit `.env` with your configuration:

```
# Core Configuration
CONFIG_SERVICE_PORT=8540
SPRING_PROFILES_ACTIVE=dev

# Git Configuration
CONFIG_GIT_URI=https://github.com/exalt-social-ecommerce-ecosystem/config-repo.git
CONFIG_GIT_USERNAME=your-username
CONFIG_GIT_PASSWORD=your-token

# Security
CONFIG_ENCRYPT_KEY=your-encryption-key
```

### 3. Build the Service

```bash
mvn clean install
```

### 4. Run Locally

```bash
# Using Maven
mvn spring-boot:run

# Or using Docker (if configured)
docker-compose up -d
```

### 5. Verify Installation

```bash
# Check service health
curl http://localhost:8540/actuator/health

# View configuration
curl http://localhost:8540/actuator/env
```

## Configuration Structure

### Directory Layout

```
config-repo/
├── application.yml           # Shared configuration
├── application-dev.yml       # Development environment
├── application-staging.yml   # Staging environment
└── application-prod.yml      # Production environment
```

### Example Configuration

```yaml
# application.yml (shared)
spring:
  application:
    name: environment-config
  cloud:
    config:
      server:
        git:
          uri: ${CONFIG_GIT_URI}
          username: ${CONFIG_GIT_USERNAME}
          password: ${CONFIG_GIT_PASSWORD}
          default-label: main

# application-dev.yml
debug: true
logging:
  level:
    root: DEBUG
    com.exalt: DEBUG

# application-prod.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when-authorized
```

## Environment Integration

### Service Configuration

Services should include:

```yaml
# bootstrap.yml
spring:
  application:
    name: your-service
  cloud:
    config:
      uri: http://environment-config:8540
      fail-fast: true
      retry:
        initial-interval: 1000
        max-interval: 2000
        max-attempts: 6
```

### Property Encryption

```bash
# Encrypt a secret
curl -X POST http://localhost:8540/encrypt -d 'your-secret-value'

# Use in configuration
password: '{cipher}encrypted-value'
```

## Verification

### Configuration Access

```bash
# Get configuration for a service
curl http://localhost:8540/your-service/default

# Get specific environment
curl http://localhost:8540/your-service/dev

# Get specific property
curl http://localhost:8540/your-service/dev/your.property
```

### Refresh Configuration

```bash
# Refresh a specific service
curl -X POST http://localhost:8540/actuator/refresh -d '{}' -H "Content-Type: application/json"

# Refresh all services
curl -X POST http://localhost:8540/actuator/bus-refresh -d '{}' -H "Content-Type: application/json"
```

## Troubleshooting

### Common Issues

#### Configuration Not Found

```bash
# Check if config server is running
curl -v http://localhost:8540/actuator/health

# Check logs
tail -f logs/application.log

# Verify Git access
git ls-remote ${CONFIG_GIT_URI}
```

#### Property Decryption Failures

1. Verify encryption key is consistent across services
2. Check for special characters in encrypted values
3. Ensure proper `{cipher}` prefix

### Logs

```bash
# View application logs
tail -f logs/application.log

# View Docker logs (if applicable)
docker-compose logs -f environment-config

# View Kubernetes logs
kubectl logs -l app=environment-config -n central-configuration
```

### Monitoring

Key metrics to monitor:

- `config.server.requests` - Configuration requests
- `config.server.failures` - Failed requests
- `config.server.encryption.operations` - Encryption operations
- `config.server.decryption.operations` - Decryption operations
