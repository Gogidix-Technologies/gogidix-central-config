# Setup Guide - Deployment Scripts

## Overview

This document provides comprehensive setup instructions for the Deployment Scripts service, including local development environment, CI/CD integration, and automation pipeline configuration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [CI/CD Integration](#ci-cd-integration)
4. [Environment Configuration](#environment-configuration)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- **Memory**: Minimum 4GB RAM (8GB recommended)
- **Storage**: Minimum 5GB free space
- **Network**: Stable internet connection

### Required Software

#### Development Tools

```bash
# Java Development Kit
Java 17+ (OpenJDK or Oracle JDK)

# Build Tool
Maven 3.8+

# IDE (Recommended)
IntelliJ IDEA or Visual Studio Code

# Version Control
Git 2.30+
```

#### CI/CD and Automation Tools

```bash
# CI/CD
GitHub Actions or Jenkins 2.375+

# Deployment Tools
Ansible 2.10+
Terraform 1.3+

# Container Tools
Docker 20.10+
```

#### Cloud Provider CLI Tools (Optional)

```bash
# AWS
AWS CLI 2.9+

# Azure
Azure CLI 2.40+

# Google Cloud
Google Cloud CLI 400.0.0+
```

### Installation Instructions

#### Java 17

**Windows:**
```powershell
# Using Chocolatey
choco install openjdk17
```

**macOS:**
```bash
# Using Homebrew
brew install openjdk@17

# Add to PATH
echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install openjdk-17-jdk

# CentOS/RHEL
sudo yum install java-17-openjdk-devel
```

#### Ansible

**Windows:**
```powershell
# Using WSL2 with Ubuntu
wsl --install -d Ubuntu
wsl sudo apt update
wsl sudo apt install ansible

# Or using Chocolatey
choco install ansible
```

**macOS:**
```bash
# Using Homebrew
brew install ansible
```

**Linux:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ansible

# CentOS/RHEL
sudo yum install ansible
```

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/deployment-scripts
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.template .env

# Edit with your local settings
nano .env
```

Required environment variables:
```properties
# Service Configuration
SERVER_PORT=8510
SPRING_PROFILES_ACTIVE=dev

# Deployment Targets Configuration
DEPLOYMENT_TARGET_DEV=http://deployment-dev:8080
DEPLOYMENT_TARGET_STAGING=http://deployment-staging:8080
DEPLOYMENT_TARGET_PROD=http://deployment-prod:8080

# GitHub Configuration (for CI/CD integration)
GITHUB_API_TOKEN=your-github-token

# Security
JWT_SECRET=your-secret-key
```

### 3. Build and Run

```bash
# Install dependencies
mvn clean install

# Run the service
mvn spring-boot:run
```

## CI/CD Integration

### GitHub Actions Integration

1. Create a GitHub Personal Access Token with appropriate permissions
2. Add the token to your repository secrets as `GITHUB_TOKEN`
3. Configure the CI/CD workflows in `.github/workflows/`:

```yaml
# Example GitHub Actions workflow
name: Deploy Scripts CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up JDK 17
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
        cache: maven
    - name: Build with Maven
      run: mvn -B package --file pom.xml
    - name: Run tests
      run: mvn test
```

### Jenkins Integration

1. Create a Jenkins pipeline job
2. Add the following Jenkinsfile to your repository:

```groovy
pipeline {
    agent any
    
    tools {
        jdk 'jdk17'
        maven 'maven3'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            steps {
                sh 'mvn clean package'
            }
        }
        
        stage('Test') {
            steps {
                sh 'mvn test'
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                sh './scripts/deploy.sh'
            }
        }
    }
    
    post {
        always {
            junit '**/target/surefire-reports/*.xml'
        }
    }
}
```

## Environment Configuration

### Multi-Environment Setup

The deployment-scripts service supports multiple deployment environments. Configure the following files for each environment:

#### Development Environment

```bash
# Create dev configuration
cp src/main/resources/application.yml src/main/resources/application-dev.yml
```

Edit `application-dev.yml`:
```yaml
deployment:
  environment: development
  target: ${DEPLOYMENT_TARGET_DEV}
  retry:
    attempts: 3
    delay: 5000
  notifications:
    enabled: true
    recipients: dev-team@example.com
```

#### Staging Environment

```bash
# Create staging configuration
cp src/main/resources/application.yml src/main/resources/application-staging.yml
```

Edit `application-staging.yml`:
```yaml
deployment:
  environment: staging
  target: ${DEPLOYMENT_TARGET_STAGING}
  retry:
    attempts: 2
    delay: 10000
  notifications:
    enabled: true
    recipients: qa-team@example.com,dev-team@example.com
```

#### Production Environment

```bash
# Create production configuration
cp src/main/resources/application.yml src/main/resources/application-prod.yml
```

Edit `application-prod.yml`:
```yaml
deployment:
  environment: production
  target: ${DEPLOYMENT_TARGET_PROD}
  retry:
    attempts: 1
    delay: 30000
  notifications:
    enabled: true
    recipients: ops-team@example.com,dev-team@example.com
```

## Verification

### Verify Installation

```bash
# Check service status
curl http://localhost:8510/actuator/health

# Expected output:
# {"status":"UP","groups":["liveness","readiness"]}
```

### Verify Deployment Scripts

```bash
# List available scripts
curl http://localhost:8510/api/v1/scripts

# Test a specific script
curl -X POST http://localhost:8510/api/v1/scripts/verify \
  -H "Content-Type: application/json" \
  -d '{"scriptId": "deployment-health-check", "environment": "dev"}'
```

## Troubleshooting

### Common Issues

#### Script Execution Failures

Issue: Deployment scripts fail to execute with permission errors

Solution:
```bash
# Ensure script permissions are set correctly
chmod +x scripts/*.sh

# Check if execution is blocked by security policies
sudo setsebool -P httpd_can_network_connect 1
```

#### CI/CD Integration Issues

Issue: GitHub Actions workflow fails with authentication errors

Solution:
```bash
# Check if GitHub token is correctly configured
1. Go to GitHub repository settings
2. Navigate to Secrets and Variables > Actions
3. Update or recreate the GITHUB_TOKEN secret
```

#### Network Connectivity Issues

Issue: Cannot connect to deployment targets

Solution:
```bash
# Verify network connectivity
ping ${DEPLOYMENT_TARGET}

# Check if firewall is blocking connections
sudo ufw status
sudo ufw allow 8510/tcp
```

If issues persist, contact the platform engineering team at platform-support@exalt-social-ecommerce.com.
