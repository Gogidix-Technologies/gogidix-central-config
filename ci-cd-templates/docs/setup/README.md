# CI/CD Templates - Enterprise Setup Guide

This comprehensive guide provides enterprise-grade instructions for setting up and configuring the CI/CD Templates service for production deployment across the Social E-commerce Ecosystem. The setup follows com.gogidix naming standards and implements industry best practices for security, scalability, and compliance.

## Prerequisites

### Infrastructure Requirements

- **Kubernetes Cluster**: v1.26+ with RBAC enabled
- **PostgreSQL Database**: v15+ with high availability setup
- **Redis Cache**: v7+ cluster with persistence
- **Container Registry**: GitHub Container Registry or private registry
- **Service Mesh**: Linkerd or Istio (recommended)
- **Monitoring Stack**: Prometheus, Grafana, and alerting
- **Log Aggregation**: ELK Stack or equivalent
- **Secrets Management**: HashiCorp Vault or cloud native

### Software Tools

- **Docker**: v24.0+ and Docker Compose v2.0+
- **kubectl**: v1.26+ with cluster admin access
- **Terraform**: v1.5+ for infrastructure provisioning
- **Helm**: v3.12+ for Kubernetes deployments
- **GitHub CLI**: v2.30+ for API interactions
- **Node.js**: v18+ LTS for build scripts
- **Java**: OpenJDK 17+ (if building Java components)
- **Python**: v3.11+ for automation scripts

### Access Requirements

- **GitHub Organization**: Admin access to gogidix-social-ecommerce-ecosystem
- **Cloud Provider**: Admin access (AWS/Azure/GCP)
- **Domain Management**: DNS configuration capabilities
- **Certificate Authority**: SSL/TLS certificate management
- **Monitoring Tools**: Access to observability platforms
- **Security Tools**: Access to vulnerability scanners

### Security Clearances

- **Background Check**: Required for production access
- **Security Training**: DevSecOps certification preferred
- **Compliance Training**: GDPR, PCI DSS, ISO 27001 awareness
- **Two-Factor Authentication**: Mandatory for all accounts

## Production Infrastructure Setup

### Phase 1: Infrastructure Provisioning

#### 1. Terraform Infrastructure Deployment

Create the production infrastructure using Terraform:

```bash
# Initialize Terraform workspace
cd infrastructure/terraform
terraform init -backend-config="bucket=gogidix-terraform-state" \
                -backend-config="key=cicd-templates/terraform.tfstate" \
                -backend-config="region=eu-west-1"

# Create workspace for environment
terraform workspace new production
terraform workspace select production

# Plan infrastructure deployment
terraform plan -var-file="environments/production.tfvars" -out=production.tfplan

# Apply infrastructure (requires approval)
terraform apply production.tfplan
```

**Production Terraform Configuration** (`environments/production.tfvars`):

```hcl
# Infrastructure Configuration
environment = "production"
region_primary = "eu-west-1"
region_secondary = "af-south-1"

# Networking
vpc_cidr = "10.0.0.0/16"
availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
enable_nat_gateway = true
enable_dns_hostnames = true
enable_dns_support = true

# Kubernetes Cluster
kubernetes_version = "1.28"
node_groups = {
  platform_services = {
    instance_types = ["m5.xlarge"]
    min_capacity = 3
    max_capacity = 10
    desired_capacity = 3
    disk_size = 100
    labels = {
      "node-type" = "platform"
      "workload" = "ci-cd-templates"
    }
    taints = [
      {
        key = "platform-services"
        value = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }
}

# Database Configuration
database = {
  engine_version = "15.3"
  instance_class = "db.r6g.xlarge"
  allocated_storage = 500
  max_allocated_storage = 2000
  multi_az = true
  backup_retention_period = 30
  backup_window = "03:00-04:00"
  maintenance_window = "sun:04:00-sun:05:00"
  enable_performance_insights = true
  monitoring_interval = 60
  deletion_protection = true
}

# Redis Configuration
redis = {
  node_type = "cache.r6g.large"
  num_cache_nodes = 3
  parameter_group_name = "default.redis7"
  port = 6379
  subnet_group_name = "gogidix-redis-subnet-group"
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled = true
}

# Security Groups
security_groups = {
  cicd_templates = {
    ingress_rules = [
      {
        from_port = 8180
        to_port = 8180
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "HTTP API access"
      },
      {
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "Management endpoints"
      }
    ]
    egress_rules = [
      {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }
}

# Monitoring
monitoring = {
  enable_cloudwatch = true
  enable_prometheus = true
  retention_in_days = 90
  alarm_email = "devops@gogidix-ecommerce.com"
}

# Backup and Recovery
backup = {
  enable_automated_backups = true
  backup_retention_days = 30
  cross_region_backup = true
  point_in_time_recovery = true
}

# Tags
common_tags = {
  Environment = "production"
  Project = "ci-cd-templates"
  Owner = "platform-team"
  CostCenter = "engineering"
  Compliance = "pci-dss,gdpr,iso27001"
  BackupPolicy = "daily"
  MonitoringPolicy = "critical"
}
```

#### 2. Kubernetes Cluster Configuration

Deploy the Kubernetes infrastructure components:

```bash
# Install essential cluster components
kubectl apply -f infrastructure/k8s/cluster-setup/

# Install service mesh (Linkerd)
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd viz install | kubectl apply -f -

# Install ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --values infrastructure/helm/ingress-nginx/production-values.yaml

# Install cert-manager for TLS
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.12.0 \
  --set installCRDs=true

# Install monitoring stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values infrastructure/helm/prometheus/production-values.yaml
```

### Phase 2: Application Setup

#### 1. Clone Repository and Setup

```bash
# Clone the repository
git clone https://github.com/gogidix-social-ecommerce-ecosystem/central-configuration/ci-cd-templates.git
cd ci-cd-templates

# Switch to production branch
git checkout main
git pull origin main

# Verify repository integrity
git verify-commit HEAD
```

#### 2. Environment Configuration

Create production environment configuration:

```bash
# Create environment-specific configuration
cp config/environments/production.env.template config/environments/production.env

# Edit production configuration (use secure editor)
nano config/environments/production.env
```

**Production Environment Configuration** (`config/environments/production.env`):

```properties
# Application Configuration
SPRING_PROFILES_ACTIVE=production,kubernetes
SERVER_PORT=8180
MANAGEMENT_SERVER_PORT=8081
APPLICATION_NAME=ci-cd-templates

# Database Configuration (use secrets)
DATABASE_URL=jdbc:postgresql://prod-postgres-cluster.cluster-abc123.eu-west-1.rds.amazonaws.com:5432/cicd_templates
DATABASE_USERNAME=${DB_USERNAME}
DATABASE_PASSWORD=${DB_PASSWORD}
DATABASE_SSL_MODE=require
DATABASE_MAX_POOL_SIZE=20
DATABASE_MIN_IDLE=5

# Redis Configuration
REDIS_HOST=prod-redis-cluster.abc123.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=${REDIS_PASSWORD}
REDIS_SSL=true
REDIS_CLUSTER_MODE=true

# GitHub Integration
GITHUB_ORG=gogidix-social-ecommerce-ecosystem
GITHUB_APP_ID=${GITHUB_APP_ID}
GITHUB_APP_PRIVATE_KEY=${GITHUB_APP_PRIVATE_KEY}
GITHUB_WEBHOOK_SECRET=${GITHUB_WEBHOOK_SECRET}

# Container Registry
CONTAINER_REGISTRY=ghcr.io/gogidix
REGISTRY_USERNAME=${REGISTRY_USERNAME}
REGISTRY_PASSWORD=${REGISTRY_PASSWORD}

# Security Configuration
JWT_SECRET=${JWT_SECRET}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
OAUTH2_CLIENT_ID=${OAUTH2_CLIENT_ID}
OAUTH2_CLIENT_SECRET=${OAUTH2_CLIENT_SECRET}

# External Services
CONFIG_SERVER_URL=https://config-server.gogidix-platform.com
SERVICE_REGISTRY_URL=https://service-registry.gogidix-platform.com
VAULT_URL=https://vault.gogidix-platform.com
VAULT_TOKEN=${VAULT_TOKEN}

# Monitoring and Observability
PROMETHEUS_ENABLED=true
JAEGER_ENABLED=true
JAEGER_ENDPOINT=http://jaeger-collector.monitoring.svc.cluster.local:14268/api/traces
LOG_LEVEL=INFO
METRICS_EXPORT_INTERVAL=30s

# Compliance and Audit
AUDIT_LOG_ENABLED=true
COMPLIANCE_MODE=strict
GDPR_MODE=enabled
PCI_DSS_MODE=enabled

# Performance Configuration
JVM_HEAP_SIZE=1g
JVM_METASPACE_SIZE=256m
CONNECTION_TIMEOUT=10s
READ_TIMEOUT=30s
WRITE_TIMEOUT=30s

# Feature Flags
FEATURE_AI_OPTIMIZATION=false
FEATURE_ADVANCED_ANALYTICS=true
FEATURE_MULTI_REGION=true
FEATURE_COMPLIANCE_AUTOMATION=true

# Regional Configuration
PRIMARY_REGION=eu-west-1
SECONDARY_REGION=af-south-1
CROSS_REGION_REPLICATION=true
```

#### 3. Secrets Management Setup

Configure HashiCorp Vault integration:

```bash
# Install Vault CLI
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install vault

# Configure Vault authentication
export VAULT_ADDR="https://vault.gogidix-platform.com"
vault auth -method=userpass username=${VAULT_USERNAME}

# Create secret engines
vault secrets enable -path=cicd-templates kv-v2

# Store production secrets
vault kv put cicd-templates/database \
  username="${DB_USERNAME}" \
  password="${DB_PASSWORD}"

vault kv put cicd-templates/redis \
  password="${REDIS_PASSWORD}"

vault kv put cicd-templates/github \
  app_id="${GITHUB_APP_ID}" \
  private_key="${GITHUB_APP_PRIVATE_KEY}" \
  webhook_secret="${GITHUB_WEBHOOK_SECRET}"

vault kv put cicd-templates/registry \
  username="${REGISTRY_USERNAME}" \
  password="${REGISTRY_PASSWORD}"

vault kv put cicd-templates/security \
  jwt_secret="${JWT_SECRET}" \
  encryption_key="${ENCRYPTION_KEY}"

vault kv put cicd-templates/oauth2 \
  client_id="${OAUTH2_CLIENT_ID}" \
  client_secret="${OAUTH2_CLIENT_SECRET}"
```

### 3. Install Dependencies

```bash
npm install
```

### 4. Initialize Template Repository

```bash
npm run init-templates
```

This will create the basic directory structure for templates:

```
templates/
├── build/
├── test/
├── security/
├── quality/
├── deploy/
└── verify/
```

## GitHub Actions Setup

### 1. Configure GitHub Actions Environment Secrets

Set up the required secrets in your GitHub organization:

```bash
# Using GitHub CLI
gh secret set DOCKER_USERNAME --org gogidix-social-ecommerce-ecosystem --body "${DOCKER_USERNAME}"
gh secret set DOCKER_PASSWORD --org gogidix-social-ecommerce-ecosystem --body "${DOCKER_PASSWORD}"
gh secret set KUBECONFIG_DEV --org gogidix-social-ecommerce-ecosystem --body "$(cat ${KUBECONFIG_DEV} | base64)"
gh secret set KUBECONFIG_TEST --org gogidix-social-ecommerce-ecosystem --body "$(cat ${KUBECONFIG_TEST} | base64)"
gh secret set KUBECONFIG_STAGE --org gogidix-social-ecommerce-ecosystem --body "$(cat ${KUBECONFIG_STAGE} | base64)"
gh secret set KUBECONFIG_PROD --org gogidix-social-ecommerce-ecosystem --body "$(cat ${KUBECONFIG_PROD} | base64)"
gh secret set SONARQUBE_TOKEN --org gogidix-social-ecommerce-ecosystem --body "${SONARQUBE_TOKEN}"
gh secret set SLACK_WEBHOOK_URL --org gogidix-social-ecommerce-ecosystem --body "${SLACK_WEBHOOK_URL}"
```

### 2. Configure GitHub Actions Environment Variables

Set up environment variables for GitHub Actions:

```bash
gh variable set DOCKER_REGISTRY --org gogidix-social-ecommerce-ecosystem --body "registry.gogidix-ecommerce.com"
gh variable set SONARQUBE_URL --org gogidix-social-ecommerce-ecosystem --body "https://sonar.gogidix-ecommerce.com"
gh variable set NOTIFICATION_EMAIL --org gogidix-social-ecommerce-ecosystem --body "devops@gogidix-ecommerce.com"
```

### 3. Configure GitHub Actions Runners

For production-grade CI/CD, set up self-hosted runners:

```bash
# Create runner group for different environments
gh api -X POST /orgs/gogidix-social-ecommerce-ecosystem/actions/runner-groups -f name="development-runners" -f visibility="private"
gh api -X POST /orgs/gogidix-social-ecommerce-ecosystem/actions/runner-groups -f name="production-runners" -f visibility="private"

# Follow GitHub instructions to set up self-hosted runners in each environment
# Documentation: https://docs.github.com/en/actions/hosting-your-own-runners/adding-self-hosted-runners
```

## Template Configuration

### 1. Core Templates Configuration

#### Configure Build Templates

Edit the core build templates for different technology stacks:

**Java/Maven Build Template** (`templates/build/java-maven-build.yml`):

```yaml
name: Java Maven Build

on:
  workflow_call:
    inputs:
      java-version:
        required: false
        type: string
        default: '17'
      maven-args:
        required: false
        type: string
        default: '-B -DskipTests'
      artifact-path:
        required: true
        type: string

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          java-version: ${{ inputs.java-version }}
          distribution: 'temurin'
          cache: 'maven'
      
      - name: Build with Maven
        run: mvn ${{ inputs.maven-args }}
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: ${{ inputs.artifact-path }}
```

**Node.js Build Template** (`templates/build/node-build.yml`):

```yaml
name: Node.js Build

on:
  workflow_call:
    inputs:
      node-version:
        required: false
        type: string
        default: '16'
      install-command:
        required: false
        type: string
        default: 'npm ci'
      build-command:
        required: false
        type: string
        default: 'npm run build'
      artifact-path:
        required: true
        type: string

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ inputs.node-version }}
          cache: 'npm'
      
      - name: Install dependencies
        run: ${{ inputs.install-command }}
      
      - name: Build
        run: ${{ inputs.build-command }}
      
      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: ${{ inputs.artifact-path }}
```

#### Configure Test Templates

Edit the core test templates for different technology stacks:

**Java Test Template** (`templates/test/java-test.yml`):

```yaml
name: Java Tests

on:
  workflow_call:
    inputs:
      java-version:
        required: false
        type: string
        default: '17'
      test-command:
        required: false
        type: string
        default: 'mvn test'
      coverage-threshold:
        required: false
        type: string
        default: '70'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          java-version: ${{ inputs.java-version }}
          distribution: 'temurin'
          cache: 'maven'
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
      
      - name: Run tests
        run: ${{ inputs.test-command }}
      
      - name: Verify code coverage
        run: |
          COVERAGE=$(grep -oP 'Total.*?([0-9]{1,3})%' target/site/jacoco/index.html | grep -oP '[0-9]{1,3}')
          if [ "$COVERAGE" -lt "${{ inputs.coverage-threshold }}" ]; then
            echo "Code coverage $COVERAGE% is below threshold ${{ inputs.coverage-threshold }}%"
            exit 1
          fi
          echo "Code coverage $COVERAGE% meets threshold ${{ inputs.coverage-threshold }}%"
      
      - name: Upload test results
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: target/surefire-reports/
```

### 2. Deployment Templates Configuration

Configure deployment templates for different environments and strategies:

**Kubernetes Deployment Template** (`templates/deploy/kubernetes-deploy.yml`):

```yaml
name: Kubernetes Deployment

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      namespace:
        required: true
        type: string
      deployment-strategy:
        required: false
        type: string
        default: 'rolling-update'
      health-check-path:
        required: false
        type: string
        default: '/health'
    secrets:
      kubeconfig:
        required: true

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
      
      - name: Configure kubeconfig
        run: |
          echo "${{ secrets.kubeconfig }}" | base64 -d > kubeconfig.yaml
          export KUBECONFIG=kubeconfig.yaml
      
      - name: Deploy to Kubernetes
        run: |
          # Use different deployment approaches based on strategy
          if [ "${{ inputs.deployment-strategy }}" == "rolling-update" ]; then
            kubectl apply -f k8s/${{ inputs.environment }}/deployment.yaml -n ${{ inputs.namespace }}
          elif [ "${{ inputs.deployment-strategy }}" == "blue-green" ]; then
            ./scripts/blue-green-deploy.sh ${{ inputs.namespace }}
          elif [ "${{ inputs.deployment-strategy }}" == "canary" ]; then
            ./scripts/canary-deploy.sh ${{ inputs.namespace }}
          else
            echo "Unknown deployment strategy: ${{ inputs.deployment-strategy }}"
            exit 1
          fi
      
      - name: Verify deployment
        run: |
          # Wait for deployment to be ready
          kubectl rollout status deployment/${SERVICE_NAME} -n ${{ inputs.namespace }} --timeout=300s
          
          # Get service URL
          SERVICE_URL=$(kubectl get svc ${SERVICE_NAME} -n ${{ inputs.namespace }} -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
          
          # Check health endpoint
          curl -f http://${SERVICE_URL}${{ inputs.health-check-path }}
      
      - name: Send deployment notification
        if: success()
        run: |
          curl -X POST -H 'Content-type: application/json' --data '{"text":"✅ Successfully deployed ${SERVICE_NAME} to ${{ inputs.environment }}"}' ${{ secrets.SLACK_WEBHOOK_URL }}
      
      - name: Send failure notification
        if: failure()
        run: |
          curl -X POST -H 'Content-type: application/json' --data '{"text":"❌ Failed to deploy ${SERVICE_NAME} to ${{ inputs.environment }}"}' ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 3. Security Templates Configuration

Configure security scanning templates:

**Dependency Check Template** (`templates/security/dependency-check.yml`):

```yaml
name: Dependency Security Scan

on:
  workflow_call:
    inputs:
      severity-threshold:
        required: false
        type: string
        default: 'MEDIUM'
      fail-on-severity:
        required: false
        type: string
        default: 'HIGH'

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
      
      - name: OWASP Dependency Check
        uses: dependency-check/Dependency-Check_Action@main
        with:
          project: '${SERVICE_NAME}'
          path: '.'
          format: 'HTML'
          out: 'reports'
          args: >
            --failOnCVSS 7
            --enableRetired
      
      - name: Upload vulnerability report
        uses: actions/upload-artifact@v3
        with:
          name: vulnerability-report
          path: reports/
      
      - name: Check for vulnerabilities
        run: |
          if grep -q "${{ inputs.fail-on-severity }}" reports/dependency-check-report.xml; then
            echo "Found ${{ inputs.fail-on-severity }} vulnerabilities"
            exit 1
          fi
```

### 4. Quality Templates Configuration

Configure code quality templates:

**SonarQube Analysis Template** (`templates/quality/sonarqube-analysis.yml`):

```yaml
name: SonarQube Analysis

on:
  workflow_call:
    inputs:
      sonar-project-key:
        required: true
        type: string
      quality-gate:
        required: false
        type: string
        default: 'default'
    secrets:
      sonar-token:
        required: true

jobs:
  sonarqube:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Set up JDK
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
      
      - name: Download build artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
      
      - name: Download test results
        uses: actions/download-artifact@v3
        with:
          name: test-results
      
      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.sonar-token }}
          SONAR_HOST_URL: ${{ vars.SONARQUBE_URL }}
        with:
          args: >
            -Dsonar.projectKey=${{ inputs.sonar-project-key }}
            -Dsonar.qualitygate.wait=true
            -Dsonar.qualitygate.name=${{ inputs.quality-gate }}
```

## Workflow Generation

### 1. Configure Service Template Generator

Edit the workflow generator script to create workflows for different service types:

```javascript
// scripts/generate-workflows.js
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

const TEMPLATE_PATH = process.env.WORKFLOW_GENERATOR_TEMPLATE_PATH || './templates';
const OUTPUT_PATH = process.env.WORKFLOW_GENERATOR_OUTPUT_PATH || './.github/workflows';

// Service configuration from input
const serviceConfig = {
  name: process.argv[2],
  type: process.argv[3], // java, node, react, etc.
  domain: process.argv[4], // social-commerce, warehousing, etc.
  environments: process.argv[5] ? process.argv[5].split(',') : ['dev', 'test', 'stage', 'prod'],
};

// Validate inputs
if (!serviceConfig.name || !serviceConfig.type || !serviceConfig.domain) {
  console.error('Usage: node generate-workflows.js <service-name> <service-type> <domain> [environments]');
  process.exit(1);
}

// Template selection based on service type
const getBuildTemplate = (type) => {
  switch (type) {
    case 'java':
      return path.join(TEMPLATE_PATH, 'build', 'java-maven-build.yml');
    case 'node':
      return path.join(TEMPLATE_PATH, 'build', 'node-build.yml');
    case 'react':
      return path.join(TEMPLATE_PATH, 'build', 'react-build.yml');
    default:
      throw new Error(`Unsupported service type: ${type}`);
  }
};

// Generate workflow
const generateWorkflow = () => {
  // Create output directory if it doesn't exist
  if (!fs.existsSync(OUTPUT_PATH)) {
    fs.mkdirSync(OUTPUT_PATH, { recursive: true });
  }
  
  // Load templates
  const buildTemplate = yaml.load(fs.readFileSync(getBuildTemplate(serviceConfig.type), 'utf8'));
  
  // Create workflow
  const workflow = {
    name: `${serviceConfig.name} CI/CD Pipeline`,
    on: {
      push: {
        branches: ['main', 'develop'],
      },
      pull_request: {
        branches: ['main', 'develop'],
      },
    },
    jobs: {
      build: buildTemplate.jobs.build,
      // Add other jobs based on templates
    },
  };
  
  // Write workflow file
  const outputFile = path.join(OUTPUT_PATH, `${serviceConfig.name}-pipeline.yml`);
  fs.writeFileSync(outputFile, yaml.dump(workflow));
  console.log(`Generated workflow: ${outputFile}`);
};

// Execute
generateWorkflow();
```

### 2. Generate Workflows for Services

Run the generator script for each service:

```bash
# Generate workflow for a Java service in the social-commerce domain
node scripts/generate-workflows.js product-service java social-commerce

# Generate workflow for a Node.js service in the warehousing domain
node scripts/generate-workflows.js inventory-api node warehousing

# Generate workflow for a React application in the centralized-dashboard domain
node scripts/generate-workflows.js analytics-dashboard react centralized-dashboard
```

## Environment Configuration

### 1. Development Environment

Configure development environment settings:

```bash
# Create development environment configuration
mkdir -p environments/development
cat > environments/development/config.json << EOF
{
  "environment": "development",
  "approval_required": false,
  "auto_deploy": true,
  "deployment_strategy": "rolling-update",
  "health_check_timeout": 60,
  "notification_channels": ["slack-dev-channel"]
}
EOF
```

### 2. Testing Environment

Configure testing environment settings:

```bash
# Create testing environment configuration
mkdir -p environments/testing
cat > environments/testing/config.json << EOF
{
  "environment": "testing",
  "approval_required": false,
  "auto_deploy": true,
  "deployment_strategy": "rolling-update",
  "health_check_timeout": 120,
  "run_integration_tests": true,
  "notification_channels": ["slack-qa-channel", "email-qa-team"]
}
EOF
```

### 3. Staging Environment

Configure staging environment settings:

```bash
# Create staging environment configuration
mkdir -p environments/staging
cat > environments/staging/config.json << EOF
{
  "environment": "staging",
  "approval_required": true,
  "approvers": ["qa-team", "dev-lead"],
  "auto_deploy": false,
  "deployment_strategy": "blue-green",
  "health_check_timeout": 180,
  "run_performance_tests": true,
  "notification_channels": ["slack-staging-channel", "email-product-team"]
}
EOF
```

### 4. Production Environment

Configure production environment settings:

```bash
# Create production environment configuration
mkdir -p environments/production
cat > environments/production/config.json << EOF
{
  "environment": "production",
  "approval_required": true,
  "approvers": ["product-owner", "ops-team"],
  "auto_deploy": false,
  "deployment_strategy": "blue-green",
  "health_check_timeout": 300,
  "notification_channels": ["slack-production-channel", "email-stakeholders", "pagerduty"]
}
EOF
```

## Integration with Other Services

### 1. Configure Integration with Config Server

Set up integration with the Config Server:

```bash
# Create Config Server integration configuration
mkdir -p integrations/config-server
cat > integrations/config-server/config.json << EOF
{
  "service_url": "https://config-server.gogidix-ecommerce.com",
  "profiles": ["dev", "test", "stage", "prod"],
  "config_refresh_endpoint": "/actuator/refresh",
  "config_fetch_timeout": 30
}
EOF
```

### 2. Configure Integration with Secrets Management

Set up integration with the Secrets Management service:

```bash
# Create Secrets Management integration configuration
mkdir -p integrations/secrets-management
cat > integrations/secrets-management/config.json << EOF
{
  "service_url": "https://vault.gogidix-ecommerce.com",
  "auth_method": "kubernetes",
  "secret_paths": {
    "database": "database/credentials",
    "api_keys": "api/keys",
    "certificates": "ssl/certificates"
  },
  "rotation_schedule": "weekly"
}
EOF
```

### 3. Configure Integration with Monitoring Service

Set up integration with the Monitoring Service:

```bash
# Create Monitoring Service integration configuration
mkdir -p integrations/monitoring
cat > integrations/monitoring/config.json << EOF
{
  "prometheus_url": "https://prometheus.gogidix-ecommerce.com",
  "grafana_url": "https://grafana.gogidix-ecommerce.com",
  "alert_endpoints": {
    "slack": "https://hooks.slack.com/services/xxx/yyy/zzz",
    "email": "ops@gogidix-ecommerce.com",
    "pagerduty": "https://events.pagerduty.com/integration/xxx/enqueue"
  },
  "metrics_prefix": "gogidix_ecommerce",
  "deployment_metrics": [
    "deployment_duration",
    "deployment_success_rate",
    "rollback_count"
  ]
}
EOF
```

## Security Configuration

### 1. Configure Security Scanning

Set up security scanning configurations:

```bash
# Create security scanning configuration
mkdir -p security/scanning
cat > security/scanning/config.json << EOF
{
  "vulnerability_threshold": "MEDIUM",
  "fail_on_severity": "HIGH",
  "scan_schedule": {
    "development": "on-commit",
    "testing": "daily",
    "staging": "daily",
    "production": "weekly"
  },
  "ignored_vulnerabilities": [
    {
      "id": "CVE-2022-12345",
      "reason": "Not applicable due to configuration",
      "until": "2023-12-31"
    }
  ],
  "notification_threshold": "LOW"
}
EOF
```

### 2. Configure Secrets Scanning

Set up secrets scanning configurations:

```bash
# Create secrets scanning configuration
mkdir -p security/secrets
cat > security/secrets/config.json << EOF
{
  "enabled": true,
  "scan_commits": true,
  "scan_pull_requests": true,
  "block_on_detection": true,
  "allowed_patterns": [
    "test_[a-zA-Z0-9]{32}"
  ],
  "notify_committer": true,
  "notify_repository_admins": true
}
EOF
```

## Deployment Strategy Configuration

### 1. Configure Blue-Green Deployment

Set up blue-green deployment configuration:

```bash
# Create blue-green deployment configuration
mkdir -p deployment-strategies/blue-green
cat > deployment-strategies/blue-green/config.json << EOF
{
  "strategy": "blue-green",
  "validation_period": 300,
  "traffic_shift_step": 20,
  "traffic_shift_interval": 60,
  "rollback_threshold": {
    "error_rate": 1.0,
    "latency_p95_ms": 500
  },
  "auto_finalize_timeout": 1800
}
EOF
```

### 2. Configure Canary Deployment

Set up canary deployment configuration:

```bash
# Create canary deployment configuration
mkdir -p deployment-strategies/canary
cat > deployment-strategies/canary/config.json << EOF
{
  "strategy": "canary",
  "initial_weight": 5,
  "increment_step": 20,
  "increment_interval": 300,
  "analysis_metrics": [
    "http_error_percentage",
    "latency_p95",
    "cpu_usage_percentage"
  ],
  "success_criteria": {
    "http_error_percentage": "< 1.0",
    "latency_p95": "< 500ms",
    "cpu_usage_percentage": "< 80.0"
  },
  "max_time_minutes": 60
}
EOF
```

## Notification Configuration

Configure notification settings:

```bash
# Create notification configuration
mkdir -p notifications
cat > notifications/config.json << EOF
{
  "channels": {
    "slack": {
      "slack-dev-channel": {
        "webhook_url": "${SLACK_WEBHOOK_URL}",
        "channel": "#dev-notifications"
      },
      "slack-qa-channel": {
        "webhook_url": "${SLACK_WEBHOOK_URL}",
        "channel": "#qa-notifications"
      },
      "slack-staging-channel": {
        "webhook_url": "${SLACK_WEBHOOK_URL}",
        "channel": "#staging-notifications"
      },
      "slack-production-channel": {
        "webhook_url": "${SLACK_WEBHOOK_URL}",
        "channel": "#production-alerts"
      }
    },
    "email": {
      "email-qa-team": {
        "recipients": ["qa@gogidix-ecommerce.com"]
      },
      "email-product-team": {
        "recipients": ["product@gogidix-ecommerce.com"]
      },
      "email-stakeholders": {
        "recipients": ["stakeholders@gogidix-ecommerce.com"]
      }
    },
    "pagerduty": {
      "service_key": "${PAGERDUTY_SERVICE_KEY}"
    }
  },
  "events": {
    "deployment_started": ["slack"],
    "deployment_succeeded": ["slack", "email"],
    "deployment_failed": ["slack", "email", "pagerduty"],
    "approval_required": ["slack", "email"],
    "security_issue_detected": ["slack", "email"]
  }
}
EOF
```

## Verification and Testing

### 1. Verify Template Generation

Test the workflow generation process:

```bash
# Run test generation
npm run test-generate-workflow

# Verify output
cat ./.github/workflows/test-service-pipeline.yml
```

### 2. Test Template Application

Apply the templates to a test service:

```bash
# Clone a test service repository
git clone https://github.com/gogidix-social-ecommerce-ecosystem/test-service.git
cd test-service

# Apply CI/CD templates
cp -r ../templates ./.github/workflows/templates
node ../scripts/generate-workflows.js test-service java social-commerce

# Commit and push to trigger workflow
git add .
git commit -m "Apply CI/CD templates"
git push
```

### 3. Test Workflow Execution

Monitor the workflow execution in GitHub Actions:

```bash
# Using GitHub CLI
gh run list -R gogidix-social-ecommerce-ecosystem/test-service
```

## Rollout Strategy

### 1. Gradual Rollout Plan

Create a phased rollout plan:

```
Phase 1: Core Infrastructure Services
- Config Server
- Service Registry
- API Gateway

Phase 2: Shared Infrastructure Services
- Authentication Service
- Logging Service
- Monitoring Service

Phase 3: Domain Services by Priority
- Critical Social Commerce Services
- Critical Warehousing Services
- Critical Courier Services

Phase 4: Remaining Services
- All other services
```

### 2. Service Migration Script

Create a script to migrate existing services to the new templates:

```bash
# Create migration script
cat > scripts/migrate-service.sh << 'EOF'
#!/bin/bash

SERVICE_NAME=$1
SERVICE_TYPE=$2
SERVICE_DOMAIN=$3

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_TYPE" ] || [ -z "$SERVICE_DOMAIN" ]; then
  echo "Usage: $0 <service-name> <service-type> <service-domain>"
  exit 1
fi

echo "Migrating service $SERVICE_NAME ($SERVICE_TYPE) in $SERVICE_DOMAIN domain..."

# Clone service repository
git clone https://github.com/gogidix-social-ecommerce-ecosystem/$SERVICE_NAME.git
cd $SERVICE_NAME

# Backup existing workflows
if [ -d ".github/workflows" ]; then
  mkdir -p .github/workflows.bak
  cp -r .github/workflows/* .github/workflows.bak/
fi

# Create templates directory
mkdir -p .github/workflows/templates

# Copy templates
cp -r ../templates/* .github/workflows/templates/

# Generate new workflow
node ../scripts/generate-workflows.js $SERVICE_NAME $SERVICE_TYPE $SERVICE_DOMAIN

# Commit and push changes
git add .
git commit -m "Migrate to standardized CI/CD templates"
git push

echo "Migration completed for $SERVICE_NAME"
EOF

# Make the script executable
chmod +x scripts/migrate-service.sh
```

## Template Customization Guide

Create a guide for service teams to customize templates within allowed boundaries:

```markdown
# CI/CD Template Customization Guide

This guide explains how to customize the CI/CD templates for your specific service needs while staying within the platform guardrails.

## Allowed Customizations

Service teams can customize the following aspects of the CI/CD templates:

1. Build parameters (JDK version, Node.js version, build arguments)
2. Test configuration (test commands, coverage thresholds)
3. Deployment parameters (health check paths, timeout values)
4. Notification recipients

## How to Customize

### 1. Create a Service-Specific Override File

In your service repository, create a `.cicd-overrides.json` file:

```json
{
  "build": {
    "java-version": "17",
    "maven-args": "-B -DskipTests -Dsome.custom.property=value"
  },
  "test": {
    "coverage-threshold": "80",
    "test-command": "mvn test -Dtest.suite=full"
  },
  "deploy": {
    "health-check-path": "/actuator/health",
    "health-check-timeout": 120
  },
  "notifications": {
    "additional-recipients": ["team-email@gogidix-ecommerce.com"]
  }
}
```

### 2. Reference Override File in Workflow

The CI/CD templates will automatically detect and apply these overrides.

## Customization Limits

The following guardrails cannot be bypassed:

1. Security scanning must be enabled
2. Quality gates cannot be disabled
3. Production deployments must have approval steps
4. Authentication to external services must use secrets
5. Direct kubectl commands are not allowed

## Example Customizations

### Custom Build for a Memory-Intensive Service

```json
{
  "build": {
    "jvm-args": "-Xmx4g -XX:+UseG1GC"
  }
}
```

### Extended Testing for a Critical Service

```json
{
  "test": {
    "coverage-threshold": "90",
    "test-command": "mvn verify -Pintegration-tests",
    "test-timeout": 1800
  }
}
```

### Custom Deployment for a Stateful Service

```json
{
  "deploy": {
    "deployment-strategy": "rolling-update",
    "max-surge": "1",
    "max-unavailable": "0",
    "readiness-probe-path": "/actuator/health/readiness",
    "liveness-probe-path": "/actuator/health/liveness"
  }
}
```

If you need further customizations beyond these boundaries, please contact the Platform Team.
```

## Maintenance and Updates

### 1. Template Update Process

Create a process for updating templates:

```bash
# Create template update script
cat > scripts/update-templates.sh << 'EOF'
#!/bin/bash

# Get all repositories in the organization
REPOS=$(gh repo list gogidix-social-ecommerce-ecosystem --json name -q '.[].name')

for REPO in $REPOS; do
  echo "Updating templates for $REPO..."
  
  # Clone repository
  git clone https://github.com/gogidix-social-ecommerce-ecosystem/$REPO.git
  cd $REPO
  
  # Check if it uses the CI/CD templates
  if [ -d ".github/workflows/templates" ]; then
    # Backup existing templates
    mkdir -p .github/workflows/templates.bak
    cp -r .github/workflows/templates/* .github/workflows/templates.bak/
    
    # Update templates
    cp -r ../templates/* .github/workflows/templates/
    
    # Commit and push changes
    git add .
    git commit -m "Update CI/CD templates to latest version"
    git push
    
    echo "Updated templates for $REPO"
  else
    echo "Skipping $REPO - does not use CI/CD templates"
  fi
  
  # Clean up
  cd ..
  rm -rf $REPO
done
EOF

# Make the script executable
chmod +x scripts/update-templates.sh
```

### 2. Version Control for Templates

Set up version tracking for templates:

```bash
# Create version file
cat > VERSION << EOF
1.0.0
EOF

# Create changelog
cat > CHANGELOG.md << EOF
# CI/CD Templates Changelog

## 1.0.0 - 2023-06-01

### Added
- Initial release of standardized CI/CD templates
- Support for Java, Node.js, and React applications
- Blue-green and canary deployment strategies
- Integration with security scanning tools
- Multi-environment deployment support
EOF
```

## Troubleshooting Guide

Create a troubleshooting guide for common issues:

```markdown
# CI/CD Templates Troubleshooting Guide

## Common Issues and Solutions

### Build Failures

#### Issue: Maven build fails due to dependency resolution problems

**Solution:**
1. Check if the Maven repository is accessible from the build environment
2. Verify that all dependencies are properly declared in pom.xml
3. Try clearing the Maven cache: `mvn clean -U`

#### Issue: Node.js build fails with "Out of memory" error

**Solution:**
1. Increase Node.js memory limit in the build configuration:
   ```json
   {
     "build": {
       "node-options": "--max-old-space-size=4096"
     }
   }
   ```

### Test Failures

#### Issue: Tests fail in CI but pass locally

**Solution:**
1. Check for environment-specific configurations
2. Ensure tests don't rely on local environment variables
3. Verify that test data is properly mocked

#### Issue: Code coverage below threshold

**Solution:**
1. Add more unit tests for uncovered code paths
2. Adjust coverage threshold if necessary (with approval)
3. Exclude generated code from coverage calculation

### Deployment Failures

#### Issue: Kubernetes deployment fails with "ImagePullBackOff"

**Solution:**
1. Verify Docker image exists in the registry
2. Check image tag is correct
3. Ensure Kubernetes has access to the image registry

#### Issue: Health check fails during deployment

**Solution:**
1. Verify the application is starting correctly
2. Check health check path configuration
3. Increase health check timeout for slower services

### Security Scan Issues

#### Issue: Security scan fails due to detected vulnerabilities

**Solution:**
1. Update dependencies to secure versions
2. Document and approve exceptions for false positives
3. Implement mitigations for vulnerabilities that cannot be updated

## How to Get Help

If you encounter issues not covered in this guide:

1. Check the CI/CD logs for detailed error messages
2. Review the templates documentation
3. Contact the Platform Team via Slack at #platform-support
4. Submit an issue on the ci-cd-templates repository
```

## Production Deployment

### Phase 3: Application Deployment

#### 1. Database Setup

Initialize the production database:

```bash
# Create database schema
kubectl apply -f k8s/database/init-job.yaml

# Verify database connection
kubectl exec -it deployment/ci-cd-templates -- \
  java -jar app.jar --spring.datasource.url=${DATABASE_URL} \
  --spring.datasource.username=${DB_USERNAME} \
  --spring.datasource.password=${DB_PASSWORD} \
  --command=validate-connection

# Run database migrations
kubectl apply -f k8s/database/migration-job.yaml

# Verify migrations
kubectl logs job/database-migration
```

#### 2. Application Deployment

Deploy the CI/CD Templates service:

```bash
# Create namespace
kubectl create namespace com-gogidix-central-config

# Apply RBAC configurations
kubectl apply -f k8s/rbac/

# Create secrets from Vault
kubectl create secret generic ci-cd-templates-secrets \
  --namespace=com-gogidix-central-config \
  --from-literal=database-url="${DATABASE_URL}" \
  --from-literal=database-username="${DB_USERNAME}" \
  --from-literal=database-password="${DB_PASSWORD}" \
  --from-literal=redis-password="${REDIS_PASSWORD}" \
  --from-literal=github-app-id="${GITHUB_APP_ID}" \
  --from-literal=github-private-key="${GITHUB_APP_PRIVATE_KEY}" \
  --from-literal=jwt-secret="${JWT_SECRET}" \
  --from-literal=encryption-key="${ENCRYPTION_KEY}"

# Deploy application
helm install ci-cd-templates ./helm/ci-cd-templates \
  --namespace com-gogidix-central-config \
  --values helm/ci-cd-templates/values-production.yaml \
  --wait --timeout=600s

# Verify deployment
kubectl get deployment ci-cd-templates -n com-gogidix-central-config
kubectl get pods -n com-gogidix-central-config -l app.kubernetes.io/name=ci-cd-templates
```

#### 3. Load Balancer and Ingress Configuration

```bash
# Apply ingress configuration
kubectl apply -f k8s/ingress/production-ingress.yaml

# Verify ingress
kubectl get ingress -n com-gogidix-central-config
kubectl describe ingress ci-cd-templates-ingress -n com-gogidix-central-config

# Test external access
curl -k https://cicd-api.gogidix-platform.com/actuator/health
```

### Phase 4: Security Hardening

#### 1. Network Policies

```bash
# Apply network policies for micro-segmentation
kubectl apply -f k8s/security/network-policies.yaml

# Verify network policies
kubectl get networkpolicy -n com-gogidix-central-config
```

#### 2. Pod Security Standards

```bash
# Apply pod security policies
kubectl apply -f k8s/security/pod-security-policies.yaml

# Verify pod security
kubectl get psp ci-cd-templates-psp
```

#### 3. Security Scanning

```bash
# Run container security scan
trivy image ghcr.io/gogidix/ci-cd-templates:latest

# Run Kubernetes configuration scan
kubesec scan k8s/deployment.yaml

# Run network security validation
kubectl apply -f k8s/security/security-tests.yaml
```

### Phase 5: Monitoring and Observability

#### 1. Metrics Configuration

```bash
# Apply ServiceMonitor for Prometheus
kubectl apply -f k8s/monitoring/service-monitor.yaml

# Verify metrics collection
kubectl get servicemonitor -n com-gogidix-central-config
```

#### 2. Logging Setup

```bash
# Configure log aggregation
kubectl apply -f k8s/logging/fluent-bit-config.yaml

# Verify log collection
kubectl logs -n kube-system -l app=fluent-bit
```

#### 3. Alerting Rules

```bash
# Apply custom alerting rules
kubectl apply -f k8s/monitoring/alert-rules.yaml

# Verify alerts
kubectl get prometheusrule -n monitoring
```

### Phase 6: Backup and Disaster Recovery

#### 1. Database Backup Configuration

```bash
# Configure automated backups
kubectl apply -f k8s/backup/database-backup-cronjob.yaml

# Verify backup schedule
kubectl get cronjob -n com-gogidix-central-config
```

#### 2. Configuration Backup

```bash
# Setup configuration backup
kubectl apply -f k8s/backup/config-backup-cronjob.yaml

# Test backup restore procedure
kubectl apply -f k8s/backup/restore-test-job.yaml
```

## Post-Deployment Validation

### 1. Health Checks

```bash
# Application health
curl https://cicd-api.gogidix-platform.com/actuator/health

# Database connectivity
curl https://cicd-api.gogidix-platform.com/actuator/health/db

# External dependencies
curl https://cicd-api.gogidix-platform.com/actuator/health/github
curl https://cicd-api.gogidix-platform.com/actuator/health/vault
```

### 2. Performance Testing

```bash
# Load testing
kubectl apply -f k8s/testing/load-test-job.yaml

# Stress testing
kubectl apply -f k8s/testing/stress-test-job.yaml

# API performance testing
k6 run scripts/performance-tests/api-load-test.js
```

### 3. Security Validation

```bash
# Run security compliance checks
kubectl apply -f k8s/testing/security-compliance-job.yaml

# Penetration testing (authorized only)
kubectl apply -f k8s/testing/pentest-job.yaml

# Vulnerability assessment
kubectl apply -f k8s/testing/vulnerability-scan-job.yaml
```

### 4. Business Continuity Testing

```bash
# Failover testing
scripts/disaster-recovery/test-failover.sh

# Backup restore testing
scripts/disaster-recovery/test-backup-restore.sh

# Regional failover testing
scripts/disaster-recovery/test-regional-failover.sh
```

## Production Readiness Checklist

### Infrastructure
- [ ] Production infrastructure deployed and verified
- [ ] Database cluster configured with high availability
- [ ] Redis cluster configured with persistence
- [ ] Load balancers configured with health checks
- [ ] SSL/TLS certificates installed and verified
- [ ] DNS records configured and propagated

### Security
- [ ] All secrets stored in HashiCorp Vault
- [ ] Network policies applied and tested
- [ ] Pod security standards enforced
- [ ] RBAC configurations applied
- [ ] Security scanning completed with no critical issues
- [ ] Compliance validation passed

### Monitoring
- [ ] Prometheus metrics collection verified
- [ ] Log aggregation configured and working
- [ ] Alerting rules configured and tested
- [ ] Dashboards created and accessible
- [ ] SLAs and SLOs defined and monitored

### Backup & Recovery
- [ ] Automated backup procedures configured
- [ ] Backup restoration tested successfully
- [ ] Disaster recovery procedures documented
- [ ] Regional failover capability verified
- [ ] Data retention policies implemented

### Documentation
- [ ] Runbooks created and reviewed
- [ ] API documentation updated and published
- [ ] Architecture documentation validated
- [ ] Security documentation reviewed
- [ ] Training materials prepared

### Team Readiness
- [ ] Operations team trained on procedures
- [ ] Development teams onboarded
- [ ] Support procedures established
- [ ] Escalation paths defined
- [ ] Change management process implemented

## Go-Live Process

### 1. Pre-Launch Activities

```bash
# Final system verification
scripts/deployment/pre-launch-verification.sh

# Performance baseline establishment
scripts/monitoring/establish-baseline.sh

# Security final scan
scripts/security/final-security-scan.sh
```

### 2. Launch Sequence

```bash
# Enable traffic routing
kubectl patch ingress ci-cd-templates-ingress -n com-gogidix-central-config \
  -p '{"metadata":{"annotations":{"nginx.ingress.kubernetes.io/rewrite-target":"/"}}}'

# Monitor launch metrics
kubectl logs -f deployment/ci-cd-templates -n com-gogidix-central-config

# Verify external access
curl -v https://cicd-api.gogidix-platform.com/v1/health
```

### 3. Post-Launch Monitoring

```bash
# Monitor key metrics for first 24 hours
scripts/monitoring/launch-monitoring.sh

# Validate SLAs
scripts/monitoring/validate-slas.sh

# Generate launch report
scripts/reporting/generate-launch-report.sh
```

## Maintenance and Operations

Refer to the [Operations Guide](../operations/README.md) for detailed information on:

- Day-to-day operational procedures
- Maintenance schedules and procedures
- Troubleshooting guides
- Performance optimization
- Security maintenance
- Compliance monitoring
- Incident response procedures

## Support and Escalation

### Technical Support
- **Level 1**: Service Desk - tickets@gogidix-platform.com
- **Level 2**: Platform Team - platform-support@gogidix-platform.com  
- **Level 3**: Architecture Team - architecture@gogidix-platform.com

### Emergency Contacts
- **On-Call Engineer**: +31-800-GOGIDIX-1 (24/7)
- **Platform Lead**: platform-lead@gogidix-platform.com
- **Security Team**: security-incident@gogidix-platform.com

### Communication Channels
- **Slack**: #platform-cicd-templates
- **Microsoft Teams**: Platform Engineering
- **Email Lists**: platform-team@gogidix-platform.com
