# Secrets Management - Operations Guide

## Overview

This document provides operational procedures, best practices, and maintenance guidelines for managing the Secrets Management service in production environments.

## Table of Contents

1. [Daily Operations](#daily-operations)
2. [Secrets Management](#secrets-management)
3. [Access Control](#access-control)
4. [Monitoring and Alerting](#monitoring-and-alerting)
5. [Disaster Recovery](#disaster-recovery)
6. [Security Operations](#security-operations)
7. [Troubleshooting](#troubleshooting)
8. [Maintenance Procedures](#maintenance-procedures)

## Daily Operations

### Service Status Checks

```bash
# Check Vault server status
vault status

# Check HA status
vault read -format=json sys/ha-status

# Check leader status
vault status -format=json | jq '.ha_enabled, .ha, .performance_standby'

# Check seal status
vault read -format=json sys/seal-status
```

### Authentication Status

```bash
# List enabled auth methods
vault auth list

# Check token accessor
vault token lookup -accessor <accessor>

# Check token capabilities
vault token capabilities <token> secret/data/myapp/config
```

## Secrets Management

### Secrets Lifecycle

```bash
# Create/Update secret
vault kv put secret/myapp/config \
  username=appuser \
  password=$(openssl rand -base64 32) \
  ttl=24h

# Read secret
vault kv get secret/myapp/config

# List secrets
vault kv list secret/

# Delete secret
vault kv delete secret/myapp/oldconfig

# Undelete secret (if versioning enabled)
vault kv undelete -versions=2 secret/myapp/config
```

### Dynamic Secrets

```bash
# Enable database secrets engine
vault secrets enable database

# Configure database connection
vault write database/config/my-postgresql \
  plugin_name=postgresql-database-plugin \
  allowed_roles="my-role" \
  connection_url="postgresql://{{username}}:{{password}}@postgres:5432/myapp" \
  username="vault" \
  password="s3cr3t"

# Create role
vault write database/roles/my-role \
  db_name=my-postgresql \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"

# Generate dynamic credentials
vault read database/creds/my-role
```

## Access Control

### Policy Management

```bash
# Create/Update policy
vault policy write myapp-policy - <<EOF
path "secret/data/myapp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

# List policies
vault policy list

# Read policy
vault policy read myapp-policy

# Delete policy
vault policy delete myapp-policy
```

### Token Management

```bash
# Create token
vault token create -policy=myapp-policy -ttl=1h

# Lookup token
vault token lookup <token>

# Renew token
vault token renew <token>

# Revoke token
vault token revoke <token>
```

## Monitoring and Alerting

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| `vault.core.unsealed` | Vault seal status | 0 (sealed) |
| `vault.token.lookup` | Token lookup operations | > 1000/s |
| `vault.expire.num_leases` | Number of active leases | > 100,000 |
| `vault.audit.log_request_failure` | Audit log failures | > 0 |
| `vault.identity.entity.creation` | Entity creation rate | 50% change from baseline |

### Alert Rules

```yaml
groups:
- name: vault.alerts
  rules:
  - alert: VaultSealed
    expr: vault_core_sealed == 1
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Vault is sealed"
      description: "Vault instance {{ $labels.instance }} is sealed"

  - alert: HighTokenUsage
    expr: rate(vault_token_create[5m]) > 1000
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "High token creation rate"
      description: "Token creation rate is {{ $value }} tokens per second"
```

## Disaster Recovery

### Backup Procedures

```bash
# Take snapshot
vault operator raft snapshot save vault.snap

# Backup audit logs
rsync -avz /var/log/vault/ backup-server:/backups/vault-logs/

# Backup configuration
vault read -format=json sys/config/state > config-state.json
```

### Restore Procedures

```bash
# Restore from snapshot
vault operator raft snapshot restore -force vault.snap

# Restore configuration
vault write sys/config/state @config-state.json

# Unseal Vault
vault operator unseal [KEY1]
vault operator unseal [KEY2]
vault operator unseal [KEY3]
```

## Security Operations

### Rotation Procedures

```bash
# Rotate encryption key
vault operator rotate

# Rotate root token
vault operator generate-root -init
vault operator generate-root -otp=[OTP] -pgp-key=[PGP_KEY]

# Rotate credentials
vault write -f auth/approle/role/myapp/secret-id
```

### Audit Logging

```bash
# Enable file audit device
vault audit enable file file_path=/var/log/vault/audit.log

# Enable syslog audit device
vault audit enable syslog tag="vault" facility="AUTH"

# List audit devices
vault audit list
```

## Troubleshooting

### Common Issues

#### Vault Unreachable

```bash
# Check Vault status
curl -s $VAULT_ADDR/v1/sys/health | jq

# Check network connectivity
telnet $VAULT_HOST 8200

# Check storage backend
vault read -format=json sys/storage/raft/configuration
```

#### Authentication Failures

```bash
# Check audit logs
sudo tail -f /var/log/vault/audit.log | jq

# Check token status
vault token lookup

# Check AppRole status
vault read auth/approle/role/myapp
```

## Maintenance Procedures

### Regular Maintenance

#### Daily

- [ ] Check Vault seal status
- [ ] Review audit logs for anomalies
- [ ] Verify backup completion
- [ ] Check token TTLs and renew if needed

#### Weekly

- [ ] Rotate encryption keys
- [ ] Review and update policies
- [ ] Clean up expired tokens
- [ ] Validate backup restoration

### Version Upgrades

1. **Pre-Upgrade Checks**
   ```bash
   # Check current version
   vault version
   
   # Take backup
   vault operator raft snapshot save pre-upgrade.snap
   
   # Verify backup
   vault operator raft snapshot restore -dry-run pre-upgrade.snap
   ```

2. **Upgrade Procedure**
   ```bash
   # Stop Vault service
   sudo systemctl stop vault
   
   # Install new version
   sudo apt update && sudo apt install vault-enterprise
   
   # Start Vault
   sudo systemctl start vault
   
   # Verify upgrade
   vault version
   ```

3. **Post-Upgrade Verification**
   ```bash
   # Check status
   vault status
   
   # Test authentication
   vault token lookup
   
   # Test secrets access
   vault kv get secret/myapp/config
   ```

### Cleanup Procedures

#### Expired Tokens

```bash
# List all accessors
tokens=$(vault list -format=json auth/token/accessors | jq -r '.[]')

# Revoke expired tokens
for token in $tokens; do
  if [ "$(vault token lookup -format=json $token | jq -r '.data.expire_time')" == "null" ]; then
    vault token revoke -accessor $token
  fi
done
```

#### Old Secret Versions

```bash
# List secret versions
vault kv metadata get secret/myapp/config

# Delete old versions
vault kv metadata delete -versions=1,2 secret/myapp/config

# Undelete if needed
vault kv undelete -versions=2 secret/myapp/config
```
