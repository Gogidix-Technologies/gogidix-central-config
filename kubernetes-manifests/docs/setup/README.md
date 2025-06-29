# Setup Guide - Kubernetes Manifests

## Overview

This document provides comprehensive setup instructions for the Kubernetes Manifests service, including local development environment, manifest creation, and deployment configuration.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Manifest Structure](#manifest-structure)
4. [Environment Configuration](#environment-configuration)
5. [Validation and Testing](#validation-and-testing)
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
# Kubernetes Tools
kubectl 1.24+
kustomize 4.5+
helm 3.8+

# Local Kubernetes Development
minikube 1.26+ or Docker Desktop with Kubernetes
k3d 5.4+ (optional)

# IDE (Recommended)
Visual Studio Code with Kubernetes extension
```

#### Validation Tools

```bash
# Manifest Validation
kubeval 0.16+
conftest 0.30+

# Security Scanning
kubesec 2.11+
trivy 0.29+
```

### Installation Instructions

#### kubectl

**Windows:**
```powershell
# Using Chocolatey
choco install kubernetes-cli

# Or manually download and install
curl -LO "https://dl.k8s.io/release/v1.24.0/bin/windows/amd64/kubectl.exe"
```

**macOS:**
```bash
# Using Homebrew
brew install kubectl

# Or manually download and install
curl -LO "https://dl.k8s.io/release/v1.24.0/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Linux:**
```bash
# Using package manager
sudo apt update
sudo apt install -y kubectl

# Or manually download and install
curl -LO "https://dl.k8s.io/release/v1.24.0/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

#### Helm

**Windows:**
```powershell
# Using Chocolatey
choco install kubernetes-helm
```

**macOS:**
```bash
# Using Homebrew
brew install helm
```

**Linux:**
```bash
# Using package manager
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```

## Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration.git
cd central-configuration/kubernetes-manifests
```

### 2. Directory Structure

```
kubernetes-manifests/
├── base/                     # Base configurations for all environments
│   ├── centralized-dashboard/  # Centralized dashboard services
│   ├── shared-infrastructure/  # Shared infrastructure services
│   ├── social-commerce/        # Social commerce services
│   ├── warehousing/            # Warehousing services
│   ├── courier-services/       # Courier services
│   ├── central-configuration/  # Central configuration services
│   └── shared-libraries/       # Shared libraries services
├── overlays/                 # Environment-specific overlays
│   ├── development/           # Development environment
│   ├── staging/               # Staging environment
│   ├── production/            # Production environment
│   └── regions/               # Region-specific configurations
│       ├── europe/            # European region
│       └── africa/            # African region
├── components/               # Reusable components
│   ├── database/              # Database components
│   ├── messaging/             # Messaging components
│   ├── monitoring/            # Monitoring components
│   └── security/              # Security components
└── scripts/                  # Helper scripts
```

### 3. Configure kubectl

```bash
# Create or update kubeconfig
mkdir -p ~/.kube
touch ~/.kube/config

# For local development with minikube
minikube start
kubectl config use-context minikube

# For cloud environment (example with AWS)
aws eks update-kubeconfig --name exalt-k8s-cluster --region eu-west-1
```

## Manifest Structure

### Base Manifests

Base manifests provide common configurations for all environments. Example structure:

```yaml
# Base deployment for a service
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: example-service
  template:
    metadata:
      labels:
        app: example-service
    spec:
      containers:
      - name: example-service
        image: example-service:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### Environment Overlays

Overlays customize base manifests for specific environments using Kustomize:

```yaml
# kustomization.yaml for production environment
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base

namespace: exalt-production

patchesStrategicMerge:
  - replica-count.yaml
  - resource-limits.yaml
  - environment-config.yaml

configMapGenerator:
  - name: production-config
    files:
      - configs/production.properties
```

## Environment Configuration

### Multi-Environment Setup

Each environment has specific configurations:

#### Development Environment

```yaml
# development/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base

namespace: exalt-dev

resources:
  - namespace.yaml

patchesStrategicMerge:
  - development-patches.yaml

configMapGenerator:
  - name: dev-config
    files:
      - configs/dev.properties
```

#### Production Environment

```yaml
# production/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
  - ../../base

namespace: exalt-production

resources:
  - namespace.yaml
  - network-policies.yaml

patchesStrategicMerge:
  - production-patches.yaml
  - high-availability.yaml
  - resource-limits.yaml

configMapGenerator:
  - name: prod-config
    files:
      - configs/prod.properties
```

## Validation and Testing

### Validate Manifests

```bash
# Validate with kubeval
kubeval --strict k8s/**/*.yaml

# Validate with conftest
conftest test k8s/

# Check for security issues
kubesec scan k8s/deployment.yaml
```

### Test Locally

```bash
# Apply to minikube
kubectl apply -k overlays/development/

# Verify deployment
kubectl get pods -n exalt-dev
kubectl get services -n exalt-dev

# Port forward to test locally
kubectl port-forward svc/example-service 8080:8080 -n exalt-dev
```

## Troubleshooting

### Common Issues

#### Invalid Manifests

Issue: `error: error validating "deployment.yaml"`

Solution:
```bash
# Fix YAML indentation issues
yamllint k8s/**/*.yaml

# Validate against specific Kubernetes version
kubeval --kubernetes-version 1.24.0 k8s/**/*.yaml
```

#### Resource Limits Issues

Issue: Pods are evicted due to resource limits

Solution:
```bash
# Check current resource usage
kubectl top pods -n exalt-dev

# Adjust resource limits in manifest
nano overlays/development/resource-limits.yaml

# Apply updated configuration
kubectl apply -k overlays/development/
```

#### Deployment Failures

Issue: Pods stuck in `ImagePullBackOff` or `CrashLoopBackOff` state

Solution:
```bash
# Check pod status
kubectl describe pod <pod-name> -n exalt-dev

# View logs
kubectl logs <pod-name> -n exalt-dev

# If image pull issue, verify image name and registry access
kubectl get secret <registry-secret> -n exalt-dev -o yaml
```

If issues persist, contact the platform engineering team at platform-support@exalt-social-ecommerce.com.
