# Secrets Management - Setup Guide

## Overview

This document provides comprehensive setup instructions for the Secrets Management service, which securely handles sensitive data across the Social E-commerce Ecosystem.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Local Development Setup](#local-development-setup)
3. [Vault Configuration](#vault-configuration)
4. [Secrets Engine Setup](#secrets-engine-setup)
5. [Authentication Methods](#authentication-methods)
6. [Access Policies](#access-policies)
7. [Verification](#verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: Linux/Unix (recommended), Windows 10/11, macOS 10.15+
- **Memory**: 4GB RAM minimum (8GB recommended)
- **Storage**: 10GB free space (for sealed data)
- **Network**: HTTPS access to Vault server

### Required Software

```bash
# Core Tools
Vault 1.13+
Consul 1.15+ (for HA mode)
Docker 20.10+ (for containerized deployment)

# CLI Tools
jq 1.6+ (for JSON processing)
yq 4.27+ (for YAML processing)

# Security Tools
OpenSSL 3.0+
GPG 2.3+

# Kubernetes (if applicable)
kubectl 1.24+
helm 3.11+
```

### Network Requirements

- Port 8200 (Vault API)
- Port 8201 (Vault cluster communication)
- Port 8500 (Consul, if used)

## Local Development Setup

### 1. Install Vault

```bash
# Linux
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault

# macOS
brew tap hashicorp/tap
brew install hashicorp/tap/vault

# Verify installation
vault --version
```

### 2. Configure Environment

Create a `.env` file from the template:

```bash
cp .env.template .env
```

Edit `.env` with your configuration:

```
# Vault Configuration
VAULT_ADDR=http://127.0.0.1:8200
VAULT_DEV_ROOT_TOKEN_ID=root-token
VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200

# Storage Backend (example: filesystem)
VAULT_STORAGE_PATH=./vault/data

# TLS Configuration (for production)
VAULT_CACERT=./tls/ca.crt
VAULT_CLIENT_CERT=./tls/vault.crt
VAULT_CLIENT_KEY=./tls/vault.key
```

### 3. Start Development Server

```bash
# Start Vault in dev mode
vault server -dev -dev-root-token-id="root-token"

# In a new terminal
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root-token'

# Verify server is running
vault status
```

## Vault Configuration

### Initialize Vault (Production)

```bash
# Initialize Vault
vault operator init -key-shares=5 -key-threshold=3

# Save the unseal keys and initial root token securely
# You'll need 3 of the 5 unseal keys to unseal the vault

# Unseal Vault
vault operator unseal [KEY1]
vault operator unseal [KEY2]
vault operator unseal [KEY3]

# Login with root token
vault login [ROOT_TOKEN]
```

### Enable Secrets Engines

```bash
# Enable key-value v2 secrets engine
vault secrets enable -path=secret -version=2 kv

# Enable PKI secrets engine
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
```

## Secrets Engine Setup

### KV Secrets Engine

```bash
# Create a secret
vault kv put secret/myapp/config username="appuser" password="s3cr3t"

# Read a secret
vault kv get secret/myapp/config

# List secrets
vault kv list secret/
```

### PKI Secrets Engine

```bash
# Generate root CA
vault write pki/root/generate/internal \
    common_name=example.com \
    ttl=87600h

# Configure URLs
vault write pki/config/urls \
    issuing_certificates="http://vault:8200/v1/pki/ca" \
    crl_distribution_points="http://vault:8200/v1/pki/crl"

# Create role
vault write pki/roles/example-dot-com \
    allowed_domains=example.com \
    allow_subdomains=true \
    max_ttl=72h
```

## Authentication Methods

### AppRole Authentication

```bash
# Enable AppRole auth method
vault auth enable approle

# Create a role
vault write auth/approle/role/myapp \
    secret_id_ttl=10m \
    token_ttl=20m \
    token_max_ttl=30m \
    policies="myapp-policy"

# Get Role ID
vault read auth/approle/role/myapp/role-id

# Get Secret ID
vault write -f auth/approle/role/myapp/secret-id
```

### Kubernetes Authentication

```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Kubernetes auth
vault write auth/kubernetes/config \
    kubernetes_host="https://kubernetes.default.svc" \
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create Kubernetes role
vault write auth/kubernetes/role/myapp \
    bound_service_account_names=myapp \
    bound_service_account_namespaces=default \
    policies=myapp-policy \
    ttl=1h
```

## Access Policies

### Example Policy

```hcl
# myapp-policy.hcl
path "secret/data/myapp/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}

path "pki/issue/example-dot-com" {
  capabilities = ["create", "update"]
}
```

### Apply Policy

```bash
# Create policy
vault policy write myapp-policy myapp-policy.hcl

# Test policy
vault policy read myapp-policy
```

## Verification

### Test Secrets Access

```bash
# Write test secret
vault kv put secret/test/verify message="Vault is working"

# Read test secret
vault kv get secret/test/verify

# Cleanup
vault kv delete secret/test/verify
```

### Test Authentication

```bash
# Using AppRole
ROLE_ID=$(vault read -field=role_id auth/approle/role/myapp/role-id)
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/myapp/secret-id)
vault write auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID

# Using Kubernetes (from a pod)
# Requires service account with proper permissions
```

## Troubleshooting

### Common Issues

#### Vault Server Not Running

```bash
# Check Vault status
vault status

# Check logs
journalctl -u vault -f

# Check storage backend
ls -l /vault/file/data
```

#### Authentication Failures

```bash
# Check auth methods
vault auth list

# Check audit logs
vault audit list

# Enable debug logging
vault monitor -log-level=debug
```

#### Unseal Issues

```bash
# Check seal status
vault status

# Check recovery keys
vault operator rekey -status

# Recover from quorum of unseal keys
vault operator unseal [KEY1]
vault operator unseal [KEY2]
vault operator unseal [KEY3]
```

### Log Collection

```bash
# Enable audit logging
vault audit enable file file_path=/var/log/vault/audit.log

# View logs
tail -f /var/log/vault/audit.log

# Collect debug information
vault debug -duration=5m -interval=10s -output=./vault-debug
```
