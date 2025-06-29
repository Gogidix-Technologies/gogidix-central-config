# Infrastructure as Code - Operations Guide

## Overview

This document provides operational procedures, best practices, and maintenance guidelines for managing the Infrastructure as Code (IaC) service in production environments.

## Table of Contents

1. [Service Management](#service-management)
2. [Change Management](#change-management)
3. [Monitoring and Alerting](#monitoring-and-alerting)
4. [Security Operations](#security-operations)
5. [Disaster Recovery](#disaster-recovery)
6. [Performance Optimization](#performance-optimization)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance Procedures](#maintenance-procedures)

## Service Management

### Service Status

```bash
# Check Terraform version
terraform version

# List workspaces
terraform workspace list

# Show current workspace
terraform workspace show
```

### State Management

```bash
# List resources in state
terraform state list

# Show resource details
terraform state show 'module.vpc.aws_vpc.this[0]'

# Move resources
terraform state mv 'module.old' 'module.new'

# Import existing resources
terraform import 'aws_vpc.main' vpc-12345678
```

### Workspace Operations

```bash
# Create new workspace
terraform workspace new staging

# Switch workspaces
terraform workspace select production

# Delete workspace
terraform workspace delete staging
```

## Change Management

### Standard Change Process

1. **Create a Feature Branch**
   ```bash
   git checkout -b feature/update-vpc-config
   ```

2. **Make Changes**
   - Update Terraform configuration files
   - Update variable files
   - Add/update modules if needed

3. **Validate Changes**
   ```bash
   terraform fmt -check
   terraform validate
   terraform plan -var-file=environments/production/terraform.tfvars
   ```

4. **Create Pull Request**
   - Link to related tickets
   - Include terraform plan output
   - Get required approvals

5. **Apply Changes**
   ```bash
   terraform apply -var-file=environments/production/terraform.tfvars
   ```

### Policy as Code

```hcl
# Example OPA policy (enforce tagging)
package terraform.analysis

deny[msg] {
    resource := input.resource_changes[_]
    resource.change.actions[_] == "create"
    not resource.change.after.tags
    msg := sprintf("Resource %s must have tags", [resource.address])
}
```

## Monitoring and Alerting

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `terraform_apply_duration` | Time to apply changes | > 10m |
| `terraform_plan_duration` | Time to generate plan | > 5m |
| `resource_count` | Number of managed resources | > 1000 |
| `state_size` | Size of Terraform state file | > 10MB |
| `drift_detection` | Number of drifted resources | > 0 |

### Alert Rules

```yaml
groups:
- name: terraform.alerts
  rules:
  - alert: TerraformApplyFailed
    expr: terraform_apply_status{status="failed"} == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Terraform apply failed in {{ $labels.environment }}"
      description: "Terraform apply failed with error: {{ $labels.error }}"

  - alert: InfrastructureDriftDetected
    expr: terraform_drift_resources > 0
    for: 30m
    labels:
      severity: warning
    annotations:
      summary: "Infrastructure drift detected in {{ $labels.environment }}"
      description: "{{ $value }} resources have drifted from their expected state"
```

## Security Operations

### Secrets Management

```bash
# Encrypt sensitive values
terraform output -json | sops --encrypt /dev/stdin > secrets.enc.json

# Decrypt for use
sops --decrypt secrets.enc.json | jq -r '.database_password'
```

### IAM Best Practices

```hcl
# Example IAM policy with least privilege
resource "aws_iam_policy" "ec2_read_only" {
  name        = "EC2ReadOnlyAccess"
  description = "Provides read-only access to EC2 instances"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      }
    ]
  })
}
```

## Disaster Recovery

### State Backup and Recovery

```bash
# Backup state
aws s3 cp s3://${TF_STATE_BUCKET}/terraform.tfstate \
  terraform.tfstate.backup-$(date +%Y%m%d-%H%M%S)

# Restore from backup
terraform state push terraform.tfstate.backup

# Recover from complete loss
terraform init -reconfigure -backend-config=environments/production/backend.hcl
```

### Workspace Recovery

```bash
# Recreate workspace
terraform workspace new production

# Import critical resources
terraform import 'module.vpc.aws_vpc.this[0]' vpc-12345678
```

## Performance Optimization

### Module Optimization

```hcl
# Use for_each instead of count for better performance
resource "aws_security_group_rule" "example" {
  for_each = {
    for rule in var.rules : rule.name => rule
  }
  
  type      = each.value.type
  from_port = each.value.from_port
  to_port   = each.value.to_port
  protocol  = each.value.protocol
  cidr_blocks = [each.value.cidr_block]
}
```

### State Optimization

```bash
# Remove old state versions
terraform state rm 'module.old'

# Clean up state history
terraform state push -force terraform.tfstate
```

## Troubleshooting

### Common Issues

#### State Locking

```bash
# Check for locks
aws dynamodb scan --table-name terraform-locks

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### Provider Authentication

```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check Azure authentication
az account show
```

#### Module Dependencies

```bash
# Visualize dependencies
terraform graph | dot -Tsvg > graph.svg

# Show resource dependencies
terraform state list | xargs -n1 terraform state show
```

## Maintenance Procedures

### Regular Maintenance

#### Weekly

- [ ] Review and clean up old workspaces
- [ ] Check for module updates
- [ ] Validate state integrity
- [ ] Review and rotate credentials

#### Monthly

- [ ] Perform state cleanup
- [ ] Review and update policies
- [ ] Test disaster recovery procedures
- [ ] Update documentation

### Version Upgrades

1. **Plan the Upgrade**
   - Review release notes for breaking changes
   - Test in non-production environments
   - Schedule maintenance window

2. **Execute Upgrade**
   ```bash
   # Update Terraform version
   tfenv install 1.5.0
   tfenv use 1.5.0
   
   # Update provider versions
   terraform init -upgrade
   ```

3. **Verify Functionality**
   ```bash
   terraform validate
   terraform plan
   ```

### Cleanup Procedures

#### Resource Cleanup

```bash
# Identify resources to remove
terraform state list

# Remove from state
terraform state rm 'module.unused'

# Destroy resources
terraform destroy -target=module.unused
```

#### Workspace Cleanup

```bash
# List all workspaces
terraform workspace list

# Delete unused workspaces
terraform workspace select old-workspace
terraform workspace delete old-workspace
```
