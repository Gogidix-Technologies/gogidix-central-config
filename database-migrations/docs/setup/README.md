# Database Migrations - Setup Guide

This guide provides instructions for setting up and configuring the Database Migrations service for use across the Social E-commerce Ecosystem.

## Prerequisites

### System Requirements

- **Java**: OpenJDK 17 or later (Eclipse Temurin recommended)
- **Build Tools**: Maven 3.9.0+ or Gradle 7.6+
- **Version Control**: Git 2.30+
- **Container Runtime**: Docker 20.10+ and Docker Compose 2.0+
- **Orchestration**: Kubernetes 1.25+ (for production deployment)
- **Cloud CLI Tools**: kubectl, helm 3.10+

### Infrastructure Requirements

- **Minimum Hardware**:
  - 4 CPU cores, 8GB RAM, 50GB storage (development)
  - 8 CPU cores, 16GB RAM, 200GB storage (production)
- **Network**: Private VPC with secure database access
- **Load Balancer**: Application Load Balancer (ALB) or equivalent
- **Storage**: High-performance SSD storage for database volumes

### Security Requirements

- **Access Control**: Active Directory/LDAP integration or OAuth2 provider
- **Secrets Management**: HashiCorp Vault, AWS Secrets Manager, or Azure Key Vault
- **SSL/TLS**: Valid certificates for all endpoints
- **Network Security**: VPN access for development, private subnets for production

### Database Requirements

- **PostgreSQL**: 13+ with extensions (pg_stat_statements, pg_buffercache)
- **MongoDB**: 5.0+ with replica set configuration
- **Redis**: 6.2+ with persistence and clustering
- **Elasticsearch**: 7.15+ with security features enabled

### Database Client Tools

- **PostgreSQL**: psql, pgAdmin 4, DBeaver
- **MongoDB**: mongosh, MongoDB Compass, Studio 3T
- **Redis**: redis-cli, RedisInsight
- **Elasticsearch**: curl, Kibana, Elasticsearch Head

### Development Tools

- **IDE**: IntelliJ IDEA Ultimate, VS Code with Java extensions
- **API Testing**: Postman, Insomnia, or similar
- **Monitoring**: Prometheus, Grafana, Jaeger for distributed tracing
- **Documentation**: Confluence, GitBook, or similar platform

## Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/exalt-social-ecommerce-ecosystem/central-configuration/database-migrations.git
cd database-migrations
```

### 2. Configure Environment Variables

Create a `.env` file based on the provided template:

```bash
cp .env.template .env
```

Edit the `.env` file to set required variables:

```properties
# Database Connection Information
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=migration_admin
POSTGRES_PASSWORD=secure_password
POSTGRES_DB=migration_registry

MONGODB_URI=mongodb://localhost:27017/migration_registry
REDIS_URI=redis://localhost:6379/0
ELASTICSEARCH_URI=http://localhost:9200

# Migration Registry Configuration
MIGRATION_REGISTRY_ENABLED=true
MIGRATION_HISTORY_RETENTION_DAYS=90
MIGRATION_LOCK_TIMEOUT_SECONDS=300

# Security Configuration
ENCRYPTION_KEY=${ENCRYPTION_KEY}
MIGRATION_ADMIN_USERNAME=admin
MIGRATION_ADMIN_PASSWORD=secure_admin_password

# Logging Configuration
LOG_LEVEL=INFO
LOG_FILE_PATH=logs/migrations.log

# Integration Configuration
CONFIG_SERVER_URI=http://localhost:8888
SECRETS_MANAGEMENT_URI=http://localhost:8200
```

### 3. Initialize Local Database

Set up the local migration registry database:

```bash
# For PostgreSQL
docker-compose up -d postgres
./scripts/init-migration-registry.sh

# For MongoDB
docker-compose up -d mongodb
./scripts/init-mongo-registry.sh
```

### 4. Build the Project

```bash
mvn clean package
```

### 5. Run Integration Tests

```bash
mvn verify
```

### 6. Start the Migration Service

```bash
java -jar target/database-migrations-1.0.0.jar
```

The Migration Service API will be available at http://localhost:8080.

## Docker Deployment

### 1. Build Docker Image

```bash
docker build -t exalt-ecommerce/database-migrations:latest .
```

### 2. Run Docker Container

```bash
docker run -p 8080:8080 --env-file .env exalt-ecommerce/database-migrations:latest
```

### 3. Docker Compose Deployment

For running with dependencies, use Docker Compose:

```bash
docker-compose up -d
```

## Kubernetes Deployment

### 1. Prepare Kubernetes Manifests

```bash
# Generate Kubernetes configuration files
./scripts/generate-k8s-configs.sh
```

This will create Kubernetes manifest files in the `k8s` directory.

### 2. Create ConfigMap and Secrets

```bash
# Create ConfigMap with non-sensitive configuration
kubectl create configmap database-migrations-config --from-file=config/application.yml

# Create Secret with sensitive configuration
kubectl create secret generic database-migrations-secrets \
  --from-literal=POSTGRES_USER=${POSTGRES_USER} \
  --from-literal=POSTGRES_PASSWORD=${POSTGRES_PASSWORD} \
  --from-literal=MONGODB_URI=${MONGODB_URI} \
  --from-literal=REDIS_URI=${REDIS_URI} \
  --from-literal=ELASTICSEARCH_URI=${ELASTICSEARCH_URI} \
  --from-literal=ENCRYPTION_KEY=${ENCRYPTION_KEY} \
  --from-literal=MIGRATION_ADMIN_PASSWORD=${MIGRATION_ADMIN_PASSWORD}
```

### 3. Deploy to Kubernetes

```bash
kubectl apply -f k8s/
```

### 4. Verify Deployment

```bash
kubectl get pods -l app=database-migrations
```

## Multi-Environment Setup

### 1. Development Environment

Configure development environment settings:

```bash
# Create development environment configuration
mkdir -p environments/development
cp config/application.yml environments/development/
```

Edit `environments/development/application.yml` to customize development settings:

```yaml
spring:
  profiles: development
  
migration:
  autoExecute: true
  validateOnStartup: true
  allowSchemaReset: true
  
logging:
  level:
    com.exalt.ecommerce.migrations: DEBUG
```

### 2. Testing Environment

Configure testing environment settings:

```bash
# Create testing environment configuration
mkdir -p environments/testing
cp config/application.yml environments/testing/
```

Edit `environments/testing/application.yml` to customize testing settings:

```yaml
spring:
  profiles: testing
  
migration:
  autoExecute: true
  validateOnStartup: true
  allowSchemaReset: true
  testDataEnabled: true
  
logging:
  level:
    com.exalt.ecommerce.migrations: INFO
```

### 3. Staging Environment

Configure staging environment settings:

```bash
# Create staging environment configuration
mkdir -p environments/staging
cp config/application.yml environments/staging/
```

Edit `environments/staging/application.yml` to customize staging settings:

```yaml
spring:
  profiles: staging
  
migration:
  autoExecute: false
  validateOnStartup: true
  allowSchemaReset: false
  approvalRequired: true
  
logging:
  level:
    com.exalt.ecommerce.migrations: INFO
```

### 4. Production Environment

Configure production environment settings:

```bash
# Create production environment configuration
mkdir -p environments/production
cp config/application.yml environments/production/
```

Edit `environments/production/application.yml` to customize production settings:

```yaml
spring:
  profiles: production
  
migration:
  autoExecute: false
  validateOnStartup: true
  allowSchemaReset: false
  approvalRequired: true
  approvalRoles: ROLE_ADMIN,ROLE_DBA
  maintenanceWindowOnly: true
  
logging:
  level:
    com.exalt.ecommerce.migrations: WARN
```

## Technology-Specific Setup

### PostgreSQL Setup

#### 1. Configure PostgreSQL Adapter

Edit `config/postgresql-adapter.yml`:

```yaml
postgresql:
  adapter:
    enabled: true
    migration:
      table: schema_version
      locations: classpath:db/migration/postgresql
      baseline-on-migrate: true
      out-of-order: false
      validate-on-migrate: true
    connection:
      init-sql: SET search_path TO public
```

#### 2. Create Migration Directory Structure

```bash
mkdir -p src/main/resources/db/migration/postgresql/{social-commerce,warehousing,courier-services,centralized-dashboard}
```

#### 3. Create Initial Migration Script

```bash
# Example for Social Commerce domain
cat > src/main/resources/db/migration/postgresql/social-commerce/V1_0_0__initial_schema.sql << EOF
-- Initial schema for Social Commerce domain

-- Create schemas
CREATE SCHEMA IF NOT EXISTS social_commerce;

-- Set search path
SET search_path TO social_commerce,public;

-- Create tables
CREATE TABLE IF NOT EXISTS vendors (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS products (
  id SERIAL PRIMARY KEY,
  vendor_id INTEGER NOT NULL REFERENCES vendors(id),
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes
CREATE INDEX idx_products_vendor_id ON products(vendor_id);
CREATE INDEX idx_products_name ON products(name);

-- Create functions
CREATE OR REPLACE FUNCTION update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
CREATE TRIGGER update_vendors_timestamp
BEFORE UPDATE ON vendors
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();

CREATE TRIGGER update_products_timestamp
BEFORE UPDATE ON products
FOR EACH ROW
EXECUTE FUNCTION update_timestamp();
EOF
```

### MongoDB Setup

#### 1. Configure MongoDB Adapter

Edit `config/mongodb-adapter.yml`:

```yaml
mongodb:
  adapter:
    enabled: true
    migration:
      collection: migration_changelog
      locations: classpath:db/migration/mongodb
      baseline-on-migrate: true
    connection:
      authentication-database: admin
```

#### 2. Create Migration Directory Structure

```bash
mkdir -p src/main/resources/db/migration/mongodb/{social-commerce,warehousing,courier-services,centralized-dashboard}
```

#### 3. Create Initial Migration Script

```bash
# Example for Warehousing domain
cat > src/main/resources/db/migration/mongodb/warehousing/V1_0_0__initial_schema.js << EOF
// Initial schema for Warehousing domain

// Create collections with validators
db.createCollection('warehouses', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['name', 'location', 'capacity'],
      properties: {
        name: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        location: {
          bsonType: 'object',
          required: ['address', 'city', 'country', 'coordinates'],
          properties: {
            address: { bsonType: 'string' },
            city: { bsonType: 'string' },
            country: { bsonType: 'string' },
            coordinates: {
              bsonType: 'array',
              items: { bsonType: 'double' }
            }
          }
        },
        capacity: {
          bsonType: 'object',
          required: ['total', 'available'],
          properties: {
            total: { bsonType: 'int' },
            available: { bsonType: 'int' },
            unit: { bsonType: 'string' }
          }
        },
        features: {
          bsonType: 'array',
          items: { bsonType: 'string' }
        },
        active: {
          bsonType: 'bool',
          description: 'must be a boolean'
        }
      }
    }
  }
});

// Create indexes
db.warehouses.createIndex({ name: 1 }, { unique: true });
db.warehouses.createIndex({ 'location.city': 1, 'location.country': 1 });
db.warehouses.createIndex({ 'location.coordinates': '2dsphere' });

// Insert initial data
db.warehouses.insertMany([
  {
    name: 'Central Warehouse',
    location: {
      address: '123 Storage Ave',
      city: 'Berlin',
      country: 'Germany',
      coordinates: [13.404954, 52.520008]
    },
    capacity: {
      total: 10000,
      available: 10000,
      unit: 'sqm'
    },
    features: ['climate-control', 'security', '24/7-access'],
    active: true,
    created_at: new Date(),
    updated_at: new Date()
  },
  {
    name: 'North Facility',
    location: {
      address: '456 Warehouse Blvd',
      city: 'Hamburg',
      country: 'Germany',
      coordinates: [9.993682, 53.551086]
    },
    capacity: {
      total: 8500,
      available: 8500,
      unit: 'sqm'
    },
    features: ['loading-dock', 'security', 'parking'],
    active: true,
    created_at: new Date(),
    updated_at: new Date()
  }
]);
EOF
```

### Redis Setup

#### 1. Configure Redis Adapter

Edit `config/redis-adapter.yml`:

```yaml
redis:
  adapter:
    enabled: true
    migration:
      key-prefix: migration:
      locations: classpath:db/migration/redis
```

#### 2. Create Migration Directory Structure

```bash
mkdir -p src/main/resources/db/migration/redis/{social-commerce,warehousing,courier-services,centralized-dashboard}
```

#### 3. Create Initial Migration Script

```bash
# Example for Courier Services domain
cat > src/main/resources/db/migration/redis/courier-services/V1_0_0__initial_schema.lua << EOF
-- Initial schema for Courier Services domain

-- Create rate limiting keys with defaults
redis.call('SET', 'courier:rate_limit:default:requests', '100')
redis.call('SET', 'courier:rate_limit:default:window', '60')

-- Create geo index for courier locations
redis.call('GEOADD', 'courier:locations', 13.361389, 38.115556, 'courier:1')
redis.call('GEOADD', 'courier:locations', 15.087269, 37.502669, 'courier:2')

-- Create sorted set for delivery priorities
redis.call('ZADD', 'courier:delivery:priorities', 10, 'express')
redis.call('ZADD', 'courier:delivery:priorities', 20, 'same-day')
redis.call('ZADD', 'courier:delivery:priorities', 30, 'next-day')
redis.call('ZADD', 'courier:delivery:priorities', 40, 'standard')

-- Create hash for courier statuses
redis.call('HSET', 'courier:statuses', 'courier:1', 'available')
redis.call('HSET', 'courier:statuses', 'courier:2', 'delivering')

-- Return success
return 'OK'
EOF
```

### Elasticsearch Setup

#### 1. Configure Elasticsearch Adapter

Edit `config/elasticsearch-adapter.yml`:

```yaml
elasticsearch:
  adapter:
    enabled: true
    migration:
      index: migration_changelog
      locations: classpath:db/migration/elasticsearch
```

#### 2. Create Migration Directory Structure

```bash
mkdir -p src/main/resources/db/migration/elasticsearch/{social-commerce,warehousing,courier-services,centralized-dashboard}
```

#### 3. Create Initial Migration Script

```bash
# Example for Centralized Dashboard domain
cat > src/main/resources/db/migration/elasticsearch/centralized-dashboard/V1_0_0__initial_indices.json << EOF
{
  "operations": [
    {
      "operation": "create_template",
      "name": "analytics_template",
      "body": {
        "index_patterns": ["analytics-*"],
        "settings": {
          "number_of_shards": 3,
          "number_of_replicas": 1,
          "refresh_interval": "30s"
        },
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "user_id": { "type": "keyword" },
            "session_id": { "type": "keyword" },
            "event_type": { "type": "keyword" },
            "page": { "type": "keyword" },
            "referrer": { "type": "keyword" },
            "device": {
              "properties": {
                "type": { "type": "keyword" },
                "os": { "type": "keyword" },
                "browser": { "type": "keyword" }
              }
            },
            "location": {
              "properties": {
                "country": { "type": "keyword" },
                "city": { "type": "keyword" },
                "coordinates": { "type": "geo_point" }
              }
            },
            "duration_ms": { "type": "long" },
            "metadata": { "type": "object", "dynamic": true }
          }
        }
      }
    },
    {
      "operation": "create_index",
      "name": "analytics-events",
      "body": {
        "aliases": {
          "analytics-current": {}
        }
      }
    },
    {
      "operation": "create_index",
      "name": "dashboard-metrics",
      "body": {
        "settings": {
          "number_of_shards": 2,
          "number_of_replicas": 1
        },
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "metric_name": { "type": "keyword" },
            "domain": { "type": "keyword" },
            "service": { "type": "keyword" },
            "environment": { "type": "keyword" },
            "region": { "type": "keyword" },
            "value": { "type": "float" },
            "unit": { "type": "keyword" },
            "tags": { "type": "keyword" }
          }
        }
      }
    }
  ]
}
EOF
```

## Integration with CI/CD

### 1. Create GitHub Actions Workflow

Create a GitHub Actions workflow file for migration execution:

```bash
mkdir -p .github/workflows
```

Create the workflow file at `.github/workflows/database-migration.yml`:

```yaml
name: Database Migration Workflow

on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy to'
        required: true
        default: 'development'
        type: choice
        options:
          - development
          - testing
          - staging
          - production
      domain:
        description: 'Domain to migrate'
        required: true
        type: choice
        options:
          - all
          - social-commerce
          - warehousing
          - courier-services
          - centralized-dashboard
      version:
        description: 'Migration version (leave empty for latest)'
        required: false
        type: string

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven
      - name: Validate migrations
        run: |
          ./mvnw clean verify -Pmigration-validate \
            -Dmigration.environment=${{ github.event.inputs.environment }} \
            -Dmigration.domain=${{ github.event.inputs.domain }} \
            -Dmigration.version=${{ github.event.inputs.version }}

  migrate:
    needs: validate
    runs-on: ubuntu-latest
    environment: ${{ github.event.inputs.environment }}
    steps:
      - uses: actions/checkout@v3
      - name: Set up JDK 17
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'
          cache: maven
      - name: Execute migrations
        run: |
          ./mvnw clean verify -Pmigration-execute \
            -Dmigration.environment=${{ github.event.inputs.environment }} \
            -Dmigration.domain=${{ github.event.inputs.domain }} \
            -Dmigration.version=${{ github.event.inputs.version }}
      - name: Verify migration
        run: |
          ./mvnw verify -Pmigration-verify \
            -Dmigration.environment=${{ github.event.inputs.environment }} \
            -Dmigration.domain=${{ github.event.inputs.domain }}
```

### 2. Configure Maven Profiles

Edit `pom.xml` to include migration profiles:

```xml
<profiles>
  <profile>
    <id>migration-validate</id>
    <properties>
      <skip.tests>true</skip.tests>
      <migration.action>validate</migration.action>
    </properties>
  </profile>
  <profile>
    <id>migration-execute</id>
    <properties>
      <skip.tests>true</skip.tests>
      <migration.action>migrate</migration.action>
    </properties>
  </profile>
  <profile>
    <id>migration-verify</id>
    <properties>
      <skip.tests>true</skip.tests>
      <migration.action>verify</migration.action>
    </properties>
  </profile>
</profiles>
```

### 3. Create Jenkins Pipeline

For organizations using Jenkins, create a Jenkinsfile:

```groovy
pipeline {
    agent any
    
    parameters {
        choice(name: 'ENVIRONMENT', choices: ['development', 'testing', 'staging', 'production'], description: 'Environment to deploy to')
        choice(name: 'DOMAIN', choices: ['all', 'social-commerce', 'warehousing', 'courier-services', 'centralized-dashboard'], description: 'Domain to migrate')
        string(name: 'VERSION', defaultValue: '', description: 'Migration version (leave empty for latest)')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Validate') {
            steps {
                sh """
                    ./mvnw clean verify -Pmigration-validate \
                      -Dmigration.environment=${params.ENVIRONMENT} \
                      -Dmigration.domain=${params.DOMAIN} \
                      -Dmigration.version=${params.VERSION}
                """
            }
        }
        
        stage('Approval') {
            when {
                expression { return params.ENVIRONMENT == 'staging' || params.ENVIRONMENT == 'production' }
            }
            steps {
                input message: "Proceed with migration to ${params.ENVIRONMENT}?", ok: 'Proceed'
            }
        }
        
        stage('Migrate') {
            steps {
                sh """
                    ./mvnw verify -Pmigration-execute \
                      -Dmigration.environment=${params.ENVIRONMENT} \
                      -Dmigration.domain=${params.DOMAIN} \
                      -Dmigration.version=${params.VERSION}
                """
            }
        }
        
        stage('Verify') {
            steps {
                sh """
                    ./mvnw verify -Pmigration-verify \
                      -Dmigration.environment=${params.ENVIRONMENT} \
                      -Dmigration.domain=${params.DOMAIN}
                """
            }
        }
    }
    
    post {
        success {
            echo "Migration completed successfully"
        }
        failure {
            echo "Migration failed"
        }
    }
}
```

## Integration with Application Services

### 1. Spring Boot Service Integration

For Spring Boot applications, add the migration client dependency:

```xml
<dependency>
  <groupId>com.exalt.ecommerce</groupId>
  <artifactId>database-migrations-client</artifactId>
  <version>1.0.0</version>
</dependency>
```

Configure the client in `application.yml`:

```yaml
spring:
  application:
    name: product-service
    
database-migrations:
  enabled: true
  domain: social-commerce
  service: product-service
  execute-on-startup: true
  registry-url: http://database-migrations:8080
```

### 2. Node.js Service Integration

For Node.js applications, install the client library:

```bash
npm install @exalt/database-migrations-client
```

Configure the client in your application:

```javascript
const { MigrationClient } = require('@exalt/database-migrations-client');

const migrationClient = new MigrationClient({
  domain: 'social-commerce',
  service: 'product-search',
  executeOnStartup: true,
  registryUrl: 'http://database-migrations:8080'
});

// Initialize migrations before starting the application
migrationClient.initializeDatabase()
  .then(() => {
    console.log('Database migrations completed successfully');
    startApplication();
  })
  .catch(error => {
    console.error('Database migration failed:', error);
    process.exit(1);
  });
```

## Security Configuration

### 1. Configure Authentication

Edit `config/security.yml` to configure authentication:

```yaml
security:
  authentication:
    type: oauth2
    oauth2:
      issuer-uri: https://auth.exalt-ecommerce.com/oauth2/default
      jwk-set-uri: https://auth.exalt-ecommerce.com/oauth2/default/v1/keys
    
  authorization:
    roles:
      ROLE_ADMIN: 
        - execute:*
        - validate:*
        - view:*
      ROLE_DBA:
        - execute:*
        - validate:*
        - view:*
      ROLE_DEVELOPER:
        - execute:development
        - execute:testing
        - validate:*
        - view:*
      ROLE_DEVOPS:
        - execute:development
        - execute:testing
        - execute:staging
        - validate:*
        - view:*
```

### 2. Configure SSL

Generate a self-signed certificate for development:

```bash
keytool -genkeypair -alias database-migrations -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore database-migrations.p12 -validity 3650
```

Configure SSL in `application.yml`:

```yaml
server:
  port: 8080
  ssl:
    enabled: true
    key-store: classpath:database-migrations.p12
    key-store-password: ${KEY_STORE_PASSWORD}
    key-store-type: PKCS12
    key-alias: database-migrations
```

## Monitoring Configuration

### 1. Configure Prometheus Integration

Add Prometheus dependency:

```xml
<dependency>
  <groupId>io.micrometer</groupId>
  <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Configure in `application.yml`:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  metrics:
    export:
      prometheus:
        enabled: true
  endpoint:
    health:
      show-details: always
```

### 2. Configure Logging

Configure logging in `application.yml`:

```yaml
logging:
  level:
    root: INFO
    com.exalt.ecommerce.migrations: INFO
  file:
    name: ${LOG_FILE_PATH:logs/migrations.log}
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"
  logback:
    rollingpolicy:
      max-file-size: 10MB
      max-history: 30
```

## Database User Setup

### 1. PostgreSQL User Setup

Create database users with appropriate permissions:

```sql
-- Migration admin user (for executing migrations)
CREATE USER migration_admin WITH PASSWORD 'secure_password';
ALTER USER migration_admin WITH SUPERUSER;

-- Application user (for normal application operations)
CREATE USER app_user WITH PASSWORD 'app_password';
GRANT CONNECT ON DATABASE your_database TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO app_user;
```

### 2. MongoDB User Setup

Create MongoDB users:

```javascript
// Switch to admin database
use admin

// Create migration admin user
db.createUser({
  user: "migration_admin",
  pwd: "secure_password",
  roles: [
    { role: "root", db: "admin" }
  ]
})

// Create application user
use your_database
db.createUser({
  user: "app_user",
  pwd: "app_password",
  roles: [
    { role: "readWrite", db: "your_database" }
  ]
})
```

### 3. Redis User Setup

Configure Redis users (Redis 6.0+):

```bash
# Connect to Redis
redis-cli

# Create users
ACL SETUSER migration_admin on >secure_password allkeys allcommands
ACL SETUSER app_user on >app_password ~* +@read +@write +@set +@list +@hash +@string +@sorted_set -@admin

# Save ACL to config
ACL SAVE
```

### 4. Elasticsearch User Setup

Configure Elasticsearch users:

```bash
# Create roles
curl -X POST "localhost:9200/_security/role/migration_admin" -H "Content-Type: application/json" -d'
{
  "cluster": ["all"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["all"]
    }
  ]
}'

curl -X POST "localhost:9200/_security/role/app_user" -H "Content-Type: application/json" -d'
{
  "cluster": ["monitor"],
  "indices": [
    {
      "names": ["your_index*"],
      "privileges": ["read", "write", "view_index_metadata"]
    }
  ]
}'

# Create users
curl -X POST "localhost:9200/_security/user/migration_admin" -H "Content-Type: application/json" -d'
{
  "password" : "secure_password",
  "roles" : ["migration_admin"],
  "full_name" : "Migration Administrator"
}'

curl -X POST "localhost:9200/_security/user/app_user" -H "Content-Type: application/json" -d'
{
  "password" : "app_password",
  "roles" : ["app_user"],
  "full_name" : "Application User"
}'
```

## Testing the Setup

### 1. Test Connection to Migration Registry

```bash
# For PostgreSQL
psql -h localhost -U migration_admin -d migration_registry -c "SELECT 1"

# For MongoDB
mongo --host localhost --username migration_admin --password --authenticationDatabase admin migration_registry --eval "db.version()"
```

### 2. Test Migration Execution

```bash
# Run a test migration
./mvnw verify -Pmigration-execute -Dmigration.environment=development -Dmigration.domain=social-commerce
```

### 3. Verify Migration Status

```bash
# Check migration status through API
curl -X GET http://localhost:8080/api/v1/migrations/status?domain=social-commerce -H "Authorization: Bearer ${TOKEN}"
```

## Troubleshooting

### Common Issues and Solutions

#### Database Connection Issues

**Issue**: Unable to connect to database
**Solution**:
1. Verify database credentials in `.env` file
2. Check database service is running
3. Verify network connectivity
4. Check firewall settings

```bash
# Test PostgreSQL connection
psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1"

# Test MongoDB connection
mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} --authenticationDatabase admin --eval "db.version()"
```

#### Migration Failures

**Issue**: Migration script fails to execute
**Solution**:
1. Check migration script syntax
2. Verify database user has sufficient permissions
3. Look for error details in logs
4. Run with debug logging enabled

```bash
# Run with debug logging
java -Dlogging.level.com.exalt.ecommerce.migrations=DEBUG -jar database-migrations.jar
```

#### Security Configuration Issues

**Issue**: Authentication or authorization failures
**Solution**:
1. Verify OAuth2 configuration
2. Check role assignments
3. Verify SSL certificate validity
4. Test with curl using valid token

```bash
# Test API with authentication
curl -X GET https://localhost:8080/api/v1/migrations/status \
  -H "Authorization: Bearer ${TOKEN}" \
  --cacert path/to/certificate
```

## Next Steps

After completing the setup:

1. Create a standard process for developing and reviewing migrations
2. Document database schema standards for each technology
3. Set up monitoring and alerting for migration failures
4. Train development teams on using the migration system
5. Integrate with deployment pipelines
6. Establish a regular database maintenance schedule
7. Create a rollback procedure for emergency situations

## Maintenance

### Backup Procedures

Set up regular backups of the migration registry:

```bash
# For PostgreSQL
pg_dump -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry > backup/migration_registry_$(date +%Y%m%d).sql

# For MongoDB
mongodump --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} --authenticationDatabase admin --db migration_registry --out backup/mongodb_$(date +%Y%m%d)
```

### Monitoring Setup

Configure alerts for migration failures:

```yaml
# Prometheus alert example
groups:
- name: DatabaseMigrationAlerts
  rules:
  - alert: MigrationFailure
    expr: migration_failures_total > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Database migration failure detected"
      description: "A database migration has failed. Check the migration service logs."
```

### Enterprise Production Configuration

### High Availability Setup

Configure the service for enterprise-grade high availability:

```yaml
# High Availability Configuration
spring:
  datasource:
    hikari:
      maximum-pool-size: 50
      minimum-idle: 10
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
      leak-detection-threshold: 60000
  
  # Multi-database configuration for HA
  flyway:
    enabled: true
    baseline-on-migrate: true
    locations: classpath:db/migration
    validate-on-migrate: true
    out-of-order: false
    clean-disabled: true
    group: true
    mixed: false
    
# Circuit Breaker Configuration
resilience4j:
  circuitbreaker:
    instances:
      database-operations:
        register-health-indicator: true
        sliding-window-size: 100
        minimum-number-of-calls: 10
        permitted-number-of-calls-in-half-open-state: 3
        wait-duration-in-open-state: 10s
        failure-rate-threshold: 50
        
# Distributed Tracing
management:
  tracing:
    sampling:
      probability: 1.0
  zipkin:
    tracing:
      endpoint: http://jaeger-collector:14268/api/traces
      
# Metrics Export
  metrics:
    export:
      prometheus:
        enabled: true
      cloudwatch:
        enabled: true
        namespace: ExaltEcommerce/DatabaseMigrations
      datadog:
        enabled: true
        api-key: ${DATADOG_API_KEY}
```

### Security Hardening

Implement enterprise security measures:

```yaml
# Security Configuration
security:
  oauth2:
    resource-server:
      jwt:
        issuer-uri: https://auth.exalt-ecommerce.com/realms/main
        jwk-set-uri: https://auth.exalt-ecommerce.com/realms/main/protocol/openid-connect/certs
        
  # Rate Limiting
  rate-limiting:
    enabled: true
    global-rate: 1000
    per-user-rate: 100
    window-size: 60s
    
  # CORS Configuration
  cors:
    allowed-origins:
      - https://dashboard.exalt-ecommerce.com
      - https://admin.exalt-ecommerce.com
    allowed-methods: [GET, POST, PUT, DELETE, OPTIONS]
    allowed-headers: [Authorization, Content-Type, X-Requested-With]
    max-age: 3600
    
  # Content Security Policy
  csp:
    policy: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
```

### Performance Optimization

Configure for optimal performance:

```yaml
# Performance Configuration
server:
  tomcat:
    threads:
      max: 200
      min-spare: 10
    connection-timeout: 20000
    accept-count: 100
    max-connections: 8192
    
# JVM Tuning
java:
  opts: |
    -Xms2g -Xmx4g
    -XX:+UseG1GC
    -XX:MaxGCPauseMillis=200
    -XX:+UnlockExperimentalVMOptions
    -XX:+UseJVMCICompiler
    -XX:+UnlockDiagnosticVMOptions
    -XX:+LogVMOutput
    -XX:LogFile=/app/logs/jvm.log
    
# Connection Pool Optimization
database:
  migration:
    pool:
      initial-size: 5
      max-active: 50
      max-idle: 20
      min-idle: 5
      validation-query: SELECT 1
      test-on-borrow: true
      test-while-idle: true
```

### Disaster Recovery Setup

Configure backup and disaster recovery:

```yaml
# Backup Configuration
backup:
  enabled: true
  schedule: "0 2 * * *"
  retention:
    daily: 7
    weekly: 4
    monthly: 12
    yearly: 5
  destinations:
    - type: s3
      bucket: exalt-ecommerce-db-backups
      region: eu-west-1
      encryption: AES256
    - type: azure-blob
      container: database-backups
      storage-account: exaltecommerce
      
# Disaster Recovery
disaster-recovery:
  enabled: true
  replication:
    mode: synchronous
    targets:
      - region: eu-central-1
        priority: 1
      - region: af-south-1
        priority: 2
  recovery-time-objective: 30m
  recovery-point-objective: 5m
```

## Regular Maintenance Tasks

Schedule regular maintenance tasks:

1. **Daily Tasks**:
   - Verify migration registry consistency
   - Check application health endpoints
   - Review error logs and alerts
   - Monitor performance metrics

2. **Weekly Tasks**:
   - Review and clean up migration history (older than 90 days)
   - Check for unused indexes and potential optimizations
   - Update security patches and dependencies
   - Performance optimization review

3. **Monthly Tasks**:
   - Update templates with latest best practices
   - Review and update documentation
   - Disaster recovery testing
   - Compliance audit and reporting

4. **Quarterly Tasks**:
   - Security vulnerability assessment
   - Capacity planning review
   - Backup and restore testing
   - Architecture review and optimization
