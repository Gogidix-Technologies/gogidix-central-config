# Kubernetes Manifests Operations

## Overview

This document provides operational procedures, monitoring guidelines, and maintenance instructions for the Kubernetes Manifests service in production environments.

## Service Operations

### Manifest Management

#### Applying Manifests

```bash
# Apply manifests to a specific environment
kubectl apply -k overlays/production/

# Apply manifests to a specific region
kubectl apply -k overlays/regions/europe/

# Apply specific service manifests
kubectl apply -f base/shared-infrastructure/api-gateway/
```

#### Rolling Updates

```bash
# Update with zero downtime
kubectl apply -k overlays/production/ --record

# Check rollout status
kubectl rollout status deployment/example-service -n gogidix-production

# Rollback if necessary
kubectl rollout undo deployment/example-service -n gogidix-production
```

#### Version Control

All manifest changes should follow GitOps principles:
1. Changes committed to git repository
2. CI/CD pipeline validates changes
3. Changes approved through pull requests
4. Automated deployment to environments

### Environment Management

```bash
# List all namespaces
kubectl get namespaces

# View resources in an environment
kubectl get all -n gogidix-production

# Check resource utilization
kubectl top pods -n gogidix-production
kubectl top nodes
```

## Monitoring and Alerting

### Key Performance Indicators

| Metric | Normal Range | Alert Threshold |
|--------|--------------|-----------------|
| Pod Availability | > 95% | < 90% |
| Resource Utilization | < 80% | > 90% |
| Deployment Success Rate | > 98% | < 95% |

### Prometheus Metrics

```yaml
# Key metrics to monitor
- kube_deployment_status_replicas_available
- kube_pod_container_status_restarts_total
- kube_pod_container_resource_requests
- kube_pod_container_resource_limits
- kube_node_status_condition
```

### Common Alerts

```yaml
# Pod availability alert
- alert: PodAvailabilityLow
  expr: kube_deployment_status_replicas_available / kube_deployment_status_replicas < 0.9
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Pod availability below 90%"
    description: "Deployment {{ $labels.deployment }} in namespace {{ $labels.namespace }} has less than 90% of pods available"
```

## Maintenance Procedures

### Regular Maintenance

1. **Update Kubernetes Version**:
   - Review release notes for new Kubernetes versions
   - Test updates in development environment
   - Schedule maintenance window
   - Apply updates with minimal downtime

2. **Manifest Auditing**:
   - Weekly review of manifest changes
   - Validate against security best practices
   - Check for resource optimization opportunities

3. **Cleanup Operations**:
   - Remove unused resources
   ```bash
   kubectl get all --all-namespaces -o json | jq '.items[] | select(.status.phase=="Failed" or .status.phase=="Succeeded") | "kubectl delete \(.kind) \(.metadata.name) -n \(.metadata.namespace)"' | xargs -n 1 bash -c
   ```
   
   - Clean orphaned volumes
   ```bash
   kubectl get pv | grep Released | awk '{print $1}' | xargs -I{} kubectl delete pv {}
   ```

## Troubleshooting

### Common Issues

#### Pod Startup Failures

1. Check pod status:
   ```bash
   kubectl describe pod <pod-name> -n gogidix-production
   ```

2. View container logs:
   ```bash
   kubectl logs <pod-name> -n gogidix-production
   ```

3. Common causes:
   - Resource constraints
   - Image pull errors
   - Configuration issues
   - Volume mount problems

#### Network Issues

1. Verify service discovery:
   ```bash
   kubectl get services -n gogidix-production
   ```

2. Test connectivity:
   ```bash
   kubectl exec -it <pod-name> -n gogidix-production -- curl <service-name>
   ```

3. Check network policies:
   ```bash
   kubectl get networkpolicies -n gogidix-production
   ```

## Disaster Recovery

### Backup Procedures

1. Regular etcd backups:
   ```bash
   ETCDCTL_API=3 etcdctl snapshot save snapshot.db
   ```

2. Export critical resources:
   ```bash
   kubectl get all -n gogidix-production -o yaml > production-backup.yaml
   ```

### Recovery Procedures

1. Restore from etcd backup:
   ```bash
   ETCDCTL_API=3 etcdctl snapshot restore snapshot.db
   ```

2. Apply saved resources:
   ```bash
   kubectl apply -f production-backup.yaml
   ```

3. Verify recovery:
   ```bash
   kubectl get pods,services,deployments -n gogidix-production
   ```

## Best Practices

1. **Resource Management**:
   - Set appropriate resource requests and limits
   - Implement horizontal pod autoscalers
   - Configure pod disruption budgets

2. **Security**:
   - Use RBAC for access control
   - Apply network policies
   - Implement pod security policies
   - Regularly scan for vulnerabilities

3. **High Availability**:
   - Deploy across multiple availability zones
   - Use pod anti-affinity rules
   - Configure proper liveness/readiness probes
