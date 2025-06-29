# Regional Deployment - Operations Guide

## Overview

This document provides operational procedures, best practices, and maintenance guidelines for managing regional deployments in production environments.

## Table of Contents

1. [Daily Operations](#daily-operations)
2. [Deployment Management](#deployment-management)
3. [Monitoring and Alerting](#monitoring-and-alerting)
4. [Disaster Recovery](#disaster-recovery)
5. [Performance Optimization](#performance-optimization)
6. [Security Operations](#security-operations)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance Procedures](#maintenance-procedures)

## Daily Operations

### Service Status Checks

```bash
# Check cluster status in all regions
for ctx in $(kubectl config get-contexts -o name); do
  echo "=== $ctx ==="
  kubectl --context=$ctx get nodes
  echo ""
done

# Check application health
kubectl get --raw /healthz
kubectl get --raw /readyz
```

### Resource Management

```bash
# List all deployments across namespaces
kubectl get deployments --all-namespaces

# Check resource usage
kubectl top pods --all-namespaces
kubectl top nodes

# Check cluster capacity
kubectl describe nodes | grep -A 5 "Allocatable"
```

## Deployment Management

### Standard Deployment Process

1. **Prepare Release**
   ```bash
   # Create release branch
   git checkout -b release/$(date +%Y%m%d)
   
   # Update version in charts
   yq eval '.version = "1.2.3"' -i charts/app/Chart.yaml
   ```

2. **Deploy to Staging**
   ```bash
   # Deploy to primary region
   helm upgrade --install app ./charts/app \
     --namespace staging \
     --values environments/staging/values.yaml \
     --set image.tag=v1.2.3
   
   # Verify deployment
   kubectl rollout status deployment/app -n staging
   ```

3. **Promote to Production**
   ```bash
   # Blue/Green deployment
   kubectl apply -f blue-green/production-blue.yaml
   
   # Verify traffic shift
   watch kubectl get svc -n production
   
   # Complete cutover
   kubectl apply -f blue-green/production-green.yaml
   ```

### Rollback Procedure

```bash
# Check rollout history
kubectl rollout history deployment/app -n production

# Rollback to previous version
kubectl rollout undo deployment/app -n production

# Verify rollback
kubectl rollout status deployment/app -n production
```
