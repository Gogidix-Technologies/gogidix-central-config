# Regional Deployment - Setup Guide

## Overview

This document provides comprehensive setup instructions for the Regional Deployment service, which manages multi-region deployments across the Social E-commerce Ecosystem.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Configuration Management](#configuration-management)
4. [Region Configuration](#region-configuration)
5. [Deployment Strategies](#deployment-strategies)
6. [Verification](#verification)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.15+, Linux Ubuntu 18.04+
- **Memory**: 8GB RAM minimum (16GB recommended)
- **Storage**: 20GB free space
- **Network**: Internet access for cloud provider APIs

### Required Software

```bash
# Core Tools
Terraform 1.4+
Kubernetes CLI 1.24+
Helm 3.11+

# Cloud Providers
AWS CLI 2.9+
Azure CLI 2.45+ (if using Azure)
Google Cloud SDK 420.0.0+ (if using GCP)

# Container Tools
Docker 20.10+
Containerd 1.6+

# Version Control
Git 2.30+
```

### Cloud Provider Access

- Multi-region access enabled in cloud provider accounts
- IAM roles with appropriate permissions
- Network connectivity between regions

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/regional-deployment
```

### 2. Configure Environment

Create a `.env` file from the template:

```bash
cp .env.template .env
```

Edit `.env` with your configuration:

```
# Environment Configuration
ENVIRONMENT=dev
PRIMARY_REGION=us-west-2
SECONDARY_REGION=us-east-1

# Kubernetes Configuration
KUBE_CONFIG_PATH=~/.kube/config

# Deployment Configuration
DEPLOYMENT_STRATEGY=blue-green
MAX_UNAVAILABLE=25%
MAX_SURGE=100%

# Monitoring Configuration
METRICS_ENABLED=true
LOGGING_LEVEL=info
```

### 3. Initialize Dependencies

```bash
# Install required tools
./scripts/install-dependencies.sh

# Initialize Terraform
terraform init -backend-config=environments/${ENVIRONMENT}/backend.hcl

# Install Helm charts
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

## Configuration Management

### Directory Structure

```
regional-deployment/
├── charts/                  # Helm charts
│   ├── app/
│   └── dependencies/
├── environments/            # Environment configs
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   ├── staging/
│   └── prod/
├── modules/                 # Reusable modules
│   ├── network/
│   ├── cluster/
│   └── deployment/
├── scripts/                 # Utility scripts
├── .gitignore
├── .terraform-version
└── versions.tf
```

### Environment Configuration

Each environment should have its own configuration in the `environments` directory:

```hcl
# environments/dev/terraform.tfvars
environment = "dev"
regions = {
  primary = {
    name     = "us-west-2"
    cidr     = "10.0.0.0/16"
    zones    = ["us-west-2a", "us-west-2b"]
    replica  = true
  }
  secondary = {
    name     = "us-east-1"
    cidr     = "10.1.0.0/16"
    zones    = ["us-east-1a", "us-east-1b"]
    replica  = true
  }
}
```

## Region Configuration

### Primary Region Setup

```hcl
# modules/primary/main.tf
module "primary_network" {
  source = "../network"
  
  name           = "${var.environment}-primary"
  region         = var.primary_region
  cidr_block     = var.primary_cidr
  enable_nat_gw  = true
  enable_vpn_gw  = true
  
  tags = merge(var.tags, {
    Environment = var.environment
    RegionType  = "primary"
  })
}
```

### Secondary Region Setup

```hcl
# modules/secondary/main.tf
module "secondary_network" {
  source = "../network"
  
  name           = "${var.environment}-secondary"
  region         = var.secondary_region
  cidr_block     = var.secondary_cidr
  enable_nat_gw  = true
  peering_config = {
    peer_region = var.primary_region
    peer_vpc_id = var.primary_vpc_id
  }
  
  tags = merge(var.tags, {
    Environment = var.environment
    RegionType  = "secondary"
  })
}
```

## Deployment Strategies

### Blue/Green Deployment

```yaml
# charts/app/values.yaml
strategy:
  type: BlueGreen
  blueGreen:
    activeService: myapp-active
    previewService: myapp-preview
    autoPromotionEnabled: false
    maxUnavailable: 25%
    prePromotion:
      analysis:
        templates:
        - templateName: success-rate
        args:
        - name: service-name
          value: myapp-preview
```

### Canary Deployment

```yaml
# charts/app/values.yaml
strategy:
  type: Canary
  canary:
    steps:
    - setWeight: 20
    - pause: {}
    - setWeight: 50
    - pause: {duration: 60}
    - setWeight: 80
    - pause: {duration: 60}
    analysis:
      interval: 1m
      threshold: 5
      templates:
      - templateName: success-rate
      args:
      - name: service-name
        value: myapp-canary
```

## Verification

### Deployment Verification

```bash
# Check deployment status
kubectl get deployments -n ${NAMESPACE}
kubectl get pods -n ${NAMESPACE}

# Check service endpoints
kubectl get svc -n ${NAMESPACE}

# Test service endpoints
curl http://${SERVICE_IP}:${PORT}/health
```

### Multi-region Verification

```bash
# Check cluster status in primary region
kubectl --context=${PRIMARY_CONTEXT} get nodes

# Check cluster status in secondary region
kubectl --context=${SECONDARY_CONTEXT} get nodes

# Verify cross-region connectivity
kubectl --context=${PRIMARY_CONTEXT} run -it --rm debug --image=busybox -- sh
> ping ${SECONDARY_SERVICE_IP}
```

## Troubleshooting

### Common Issues

#### Cross-region Connectivity

```bash
# Check VPC peering connections
aws ec2 describe-vpc-peering-connections --region ${REGION}

# Check route tables
aws ec2 describe-route-tables --filters Name=vpc-id,Values=${VPC_ID} --region ${REGION}

# Test network connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot -- /bin/bash
> curl -v http://${SERVICE_IP}:${PORT}
> traceroute ${SERVICE_IP}
```

#### Deployment Failures

```bash
# Check deployment events
kubectl describe deployment ${DEPLOYMENT} -n ${NAMESPACE}

# Check pod logs
kubectl logs -l app=${APP_NAME} -n ${NAMESPACE}

# Check pod events
kubectl get events --sort-by='.metadata.creationTimestamp' -n ${NAMESPACE}
```

### Log Collection

```bash
# Collect logs from all pods
kubectl logs -l app=${APP_NAME} --all-containers -n ${NAMESPACE} > all-pods.log

# Describe all resources
kubectl get all,ingress,configmap,secret -n ${NAMESPACE} -o yaml > cluster-state.yaml

# Export metrics
kubectl get --raw /metrics > metrics.txt
```
