# Configuration Server - Setup Guide

This comprehensive guide provides step-by-step instructions for setting up and deploying the Configuration Server service across different environments, from local development to production multi-region deployments.

## Prerequisites

### Software Requirements

- **Java Development Kit (JDK)**: Version 17 or later (OpenJDK recommended)
- **Apache Maven**: Version 3.8.0 or later
- **Git Client**: Version 2.30 or later
- **Docker**: Version 20.10 or later
- **Docker Compose**: Version 2.0 or later
- **Kubernetes**: Version 1.24 or later (for production deployment)
- **kubectl**: Compatible with your Kubernetes cluster version
- **Helm**: Version 3.10 or later (optional, for advanced deployments)

### Infrastructure Requirements

- **Git Repository**: Access to configuration repository (GitHub/GitLab Enterprise)
- **SSL Certificates**: Valid certificates for HTTPS communication
- **Service Discovery**: Eureka Server or Kubernetes service discovery
- **Message Broker**: RabbitMQ or Apache Kafka for configuration events
- **Monitoring Stack**: Prometheus, Grafana, and ELK stack
- **Secret Management**: HashiCorp Vault or Kubernetes secrets
- **Load Balancer**: HAProxy, NGINX, or cloud load balancer

### Network Requirements

- **Ports**: 8888 (Config Server), 8761 (Eureka), 5432 (PostgreSQL), 6379 (Redis)
- **Firewall Rules**: Allow inbound traffic on required ports
- **DNS Resolution**: Proper DNS configuration for service discovery
- **Security Groups**: Configured for inter-service communication

## Local Development Setup

### 1. Clone the Repository

```bash
git clone https://github.com/gogidix-social-ecommerce-ecosystem/central-configuration/config-server.git
cd config-server
```

### 2. Configure Environment Variables

Create a `.env` file based on the provided template:

```bash
cp .env.template .env
```

Edit the `.env` file to set required variables:

```properties
# Git Repository Configuration
SPRING_CLOUD_CONFIG_SERVER_GIT_URI=https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git
SPRING_CLOUD_CONFIG_SERVER_GIT_USERNAME=${GIT_USERNAME}
SPRING_CLOUD_CONFIG_SERVER_GIT_PASSWORD=${GIT_PASSWORD}

# Server Configuration
SERVER_PORT=8888
SPRING_PROFILES_ACTIVE=native,git

# Security Configuration
SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_ISSUER_URI=https://auth.gogidix-ecommerce.com/oauth2/default
SPRING_SECURITY_OAUTH2_RESOURCESERVER_JWT_JWK_SET_URI=https://auth.gogidix-ecommerce.com/oauth2/default/v1/keys

# Encryption Configuration
ENCRYPT_KEY=${ENCRYPTION_KEY}

# Monitoring Configuration
MANAGEMENT_ENDPOINTS_WEB_EXPOSURE_INCLUDE=health,info,metrics,env,refresh
```

### 3. Configure Application Properties

Create a local application configuration file:

```bash
mkdir -p src/main/resources
cp src/main/resources/application.yml.template src/main/resources/application.yml
```

Customize the `application.yml` file as needed for your local environment.

### 4. Build the Application

```bash
mvn clean package -DskipTests
```

### 5. Run Local Tests

```bash
mvn test
```

### 6. Start the Application

```bash
mvn spring-boot:run
```

The Configuration Server will be available at http://localhost:8888.

## Docker Deployment

### 1. Build Docker Image

```bash
docker build -t gogidix-ecommerce/config-server:latest .
```

### 2. Run Docker Container

```bash
docker run -p 8888:8888 --env-file .env gogidix-ecommerce/config-server:latest
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
./generate-k8s-configs.sh config-server
```

This will create Kubernetes manifest files in the `k8s` directory.

### 2. Create ConfigMap and Secrets

```bash
# Create ConfigMap with non-sensitive configuration
kubectl create configmap config-server-config --from-file=config/application.yml

# Create Secret with sensitive configuration
kubectl create secret generic config-server-secrets \
  --from-literal=SPRING_CLOUD_CONFIG_SERVER_GIT_USERNAME=${GIT_USERNAME} \
  --from-literal=SPRING_CLOUD_CONFIG_SERVER_GIT_PASSWORD=${GIT_PASSWORD} \
  --from-literal=ENCRYPT_KEY=${ENCRYPTION_KEY}
```

### 3. Deploy to Kubernetes

```bash
kubectl apply -f k8s/
```

### 4. Verify Deployment

```bash
kubectl get pods -l app=config-server
```

## High Availability Deployment

For production environments, deploy multiple instances with load balancing:

### 1. Update Resource Allocations

Modify the `k8s/deployment.yaml` file to allocate appropriate resources:

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### 2. Configure Horizontal Pod Autoscaler

Create an HPA for automatic scaling:

```bash
kubectl autoscale deployment config-server --cpu-percent=70 --min=3 --max=10
```

### 3. Deploy Across Multiple Availability Zones

Label nodes with availability zones and use node affinity rules:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: topology.kubernetes.io/zone
          operator: In
          values:
          - eu-west-1a
          - eu-west-1b
          - eu-west-1c
```

## Multi-Region Deployment

### 1. Deploy to European Region

```bash
kubectl config use-context europe-cluster
kubectl apply -f k8s/europe/
```

### 2. Deploy to African Region

```bash
kubectl config use-context africa-cluster
kubectl apply -f k8s/africa/
```

### 3. Configure Cross-Region Replication

Set up Git synchronization between regions:

```yaml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git
          clone-on-start: true
          force-pull: true
          refresh-rate: 30
```

## Configuration Repository Setup

### 1. Initialize Configuration Repository

```bash
git clone https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git
cd configuration-repository
```

### 2. Create Base Directory Structure

```bash
mkdir -p application service-domains/social-commerce service-domains/warehousing service-domains/courier-services service-domains/centralized-dashboard regions/europe regions/africa infrastructure
```

### 3. Create Initial Configuration Files

Create default application properties:

```bash
cat > application/application.yml << EOF
# Common configuration for all applications
spring:
  application:
    name: config-server
  profiles:
    active: native,git

server:
  port: 8888

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,env,refresh
  endpoint:
    health:
      show-details: always

logging:
  level:
    root: INFO
    org.springframework.cloud.config: DEBUG
EOF
```

### 4. Push to Repository

```bash
git add .
git commit -m "Initial configuration setup"
git push origin main
```

## Security Setup

### 1. Configure SSL

Generate a self-signed certificate for development:

```bash
keytool -genkeypair -alias config-server -keyalg RSA -keysize 2048 -storetype PKCS12 -keystore config-server.p12 -validity 3650
```

For production, use properly signed certificates from a trusted CA.

### 2. Configure TLS in application.yml

```yaml
server:
  port: 8888
  ssl:
    key-store: classpath:config-server.p12
    key-store-password: ${KEY_STORE_PASSWORD}
    key-store-type: PKCS12
    key-alias: config-server
```

### 3. Configure Authentication

Set up OAuth2/OIDC integration:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://auth.gogidix-ecommerce.com/oauth2/default
          jwk-set-uri: https://auth.gogidix-ecommerce.com/oauth2/default/v1/keys
```

## Monitoring Setup

### 1. Configure Prometheus Integration

Add Prometheus dependency:

```xml
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>
```

Configure in application.yml:

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
```

### 2. Configure Actuator Endpoints

```yaml
management:
  endpoint:
    health:
      show-details: always
    env:
      post:
        enabled: true
  health:
    db:
      enabled: true
    diskspace:
      enabled: true
```

### 3. Set Up Grafana Dashboard

Import the provided Grafana dashboard template from:

```
monitoring/dashboards/config-server-dashboard.json
```

## Encryption Configuration

### 1. Generate Encryption Key

```bash
openssl genrsa -out config-encryption.pem 2048
export ENCRYPT_KEY=$(cat config-encryption.pem | base64)
```

### 2. Configure Encryption

Add the encryption key to the environment:

```properties
ENCRYPT_KEY=${ENCRYPT_KEY}
```

### 3. Test Encryption

Encrypt a sample value:

```bash
curl -X POST http://localhost:8888/encrypt -d 'sensitive-value'
```

Decrypt a sample value:

```bash
curl -X POST http://localhost:8888/decrypt -d '{encrypted-value}'
```

## Troubleshooting

### Common Issues

1. **Git Connectivity Issues**:
   - Verify Git credentials
   - Check network connectivity to Git repository
   - Ensure proper SSH key setup if using SSH

2. **JVM Memory Issues**:
   - Increase heap size: `-Xmx1024m`
   - Enable GC logging: `-Xlog:gc*:file=gc.log`

3. **Security Configuration Issues**:
   - Verify JWT issuer URI
   - Check certificate validity
   - Ensure proper CORS configuration

4. **Performance Issues**:
   - Increase Git timeout settings
   - Configure proper caching
   - Adjust thread pool settings

### Diagnostic Commands

Check service status:

```bash
curl -k https://localhost:8888/actuator/health
```

View environment properties:

```bash
curl -k https://localhost:8888/actuator/env
```

View available configurations:

```bash
curl -k https://localhost:8888/actuator/configprops
```

## Upgrade Process

### 1. Backup Current Configuration

```bash
# Backup configuration files
cp -r src/main/resources backup/
```

### 2. Update Dependencies

Update version numbers in pom.xml:

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.1.2</version>
</parent>

<properties>
    <spring-cloud.version>2022.0.4</spring-cloud.version>
</properties>
```

### 3. Build and Test New Version

```bash
mvn clean package
```

### 4. Deploy Update

For Kubernetes:

```bash
kubectl set image deployment/config-server config-server=gogidix-ecommerce/config-server:${NEW_VERSION}
```

For Docker:

```bash
docker-compose up -d --build
```

### 5. Verify Upgrade

```bash
curl -k https://localhost:8888/actuator/info
```

## Production-Ready Configuration Templates

### Enterprise Application Configuration

Create production-ready configuration templates:

```yaml
# application-prod.yml
spring:
  application:
    name: config-server
  profiles:
    active: prod,git,encrypt,vault
  cloud:
    config:
      server:
        git:
          uri: ${CONFIG_GIT_URI}
          default-label: ${CONFIG_GIT_BRANCH:main}
          search-paths: '{application}/{profile}','{application}','{profile}'
          username: ${CONFIG_GIT_USERNAME}
          password: ${CONFIG_GIT_PASSWORD}
          clone-on-start: true
          force-pull: true
          timeout: 30
          refresh-rate: 60
        encrypt:
          enabled: true
        vault:
          host: ${VAULT_HOST:vault.gogidix-ecommerce.com}
          port: ${VAULT_PORT:8200}
          scheme: https
          backend: secret
          default-key: config-server
          
server:
  port: 8888
  ssl:
    enabled: true
    key-store: classpath:keystore.p12
    key-store-password: ${KEYSTORE_PASSWORD}
    key-store-type: PKCS12
    key-alias: config-server
  tomcat:
    max-threads: 200
    min-spare-threads: 20
    max-connections: 8192
    accept-count: 100

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus,env,configprops,refresh,busrefresh
  endpoint:
    health:
      show-details: always
      probes:
        enabled: true
  metrics:
    export:
      prometheus:
        enabled: true
  health:
    readiness-state:
      enabled: true
    liveness-state:
      enabled: true

logging:
  level:
    root: INFO
    com.gogidix: DEBUG
    org.springframework.cloud.config: INFO
    org.springframework.security: WARN
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level [%X{traceId:-},%X{spanId:-}] %logger{36} - %msg%n"
  file:
    name: /var/log/config-server/application.log

# Security Configuration
spring.security:
  oauth2:
    resourceserver:
      jwt:
        issuer-uri: ${JWT_ISSUER_URI:https://auth.gogidix-ecommerce.com/oauth2/default}
        jwk-set-uri: ${JWT_JWK_SET_URI:https://auth.gogidix-ecommerce.com/oauth2/default/v1/keys}

# Encryption Configuration
encrypt:
  key-store:
    location: classpath:config-server.jks
    password: ${ENCRYPT_KEYSTORE_PASSWORD}
    alias: config-server-encrypt
    secret: ${ENCRYPT_KEY_PASSWORD}

# Message Bus Configuration (RabbitMQ)
spring.rabbitmq:
  host: ${RABBITMQ_HOST:rabbitmq.gogidix-ecommerce.com}
  port: ${RABBITMQ_PORT:5672}
  username: ${RABBITMQ_USERNAME}
  password: ${RABBITMQ_PASSWORD}
  ssl:
    enabled: true
    trust-store: classpath:rabbitmq-truststore.p12
    trust-store-password: ${RABBITMQ_TRUSTSTORE_PASSWORD}

# Database Configuration (PostgreSQL)
spring.datasource:
  url: jdbc:postgresql://${DB_HOST:postgres.gogidix-ecommerce.com}:${DB_PORT:5432}/${DB_NAME:config_server}
  username: ${DB_USERNAME}
  password: ${DB_PASSWORD}
  hikari:
    maximum-pool-size: 20
    minimum-idle: 5
    connection-timeout: 30000
    idle-timeout: 600000
    max-lifetime: 1800000

# Cache Configuration (Redis)
spring.cache:
  type: redis
  redis:
    host: ${REDIS_HOST:redis.gogidix-ecommerce.com}
    port: ${REDIS_PORT:6379}
    password: ${REDIS_PASSWORD}
    ssl:
      enabled: true
    timeout: 2000ms
    jedis:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0
```

### Multi-Region Deployment Configuration

Configure for multi-region deployments:

```yaml
# application-europe.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/gogidix-social-ecommerce-ecosystem/config-europe.git
          search-paths: 'europe/{application}/{profile}','europe/{application}','europe/{profile}'

eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-europe-1.gogidix-ecommerce.com:8761/eureka/,http://eureka-europe-2.gogidix-ecommerce.com:8761/eureka/

management:
  metrics:
    tags:
      region: europe
      availability-zone: ${AVAILABILITY_ZONE:eu-west-1a}
```

```yaml
# application-africa.yml
spring:
  cloud:
    config:
      server:
        git:
          uri: https://github.com/gogidix-social-ecommerce-ecosystem/config-africa.git
          search-paths: 'africa/{application}/{profile}','africa/{application}','africa/{profile}'

eureka:
  client:
    serviceUrl:
      defaultZone: http://eureka-africa-1.gogidix-ecommerce.com:8761/eureka/,http://eureka-africa-2.gogidix-ecommerce.com:8761/eureka/

management:
  metrics:
    tags:
      region: africa
      availability-zone: ${AVAILABILITY_ZONE:af-south-1a}
```

## Advanced Deployment Scenarios

### Blue-Green Deployment

Configure blue-green deployment for zero-downtime updates:

```bash
# Deploy green version alongside blue
kubectl apply -f k8s/green-deployment.yaml

# Verify green deployment health
kubectl get pods -l app=config-server,deployment=green

# Switch traffic to green
kubectl patch service config-server -p '{"spec":{"selector":{"deployment":"green"}}}'

# Remove blue deployment after validation
kubectl delete deployment config-server-blue
```

### Canary Deployment

Implement canary deployment for gradual rollout:

```yaml
# canary-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: config-server-canary
spec:
  selector:
    app: config-server
    version: canary
  ports:
    - port: 8888
      targetPort: 8888
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: config-server-vs
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: config-server-canary
  - route:
    - destination:
        host: config-server
      weight: 90
    - destination:
        host: config-server-canary
      weight: 10
```

### High Availability Setup

Configure for 99.99% availability:

```yaml
# ha-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-server
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 1
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: topology.kubernetes.io/zone
                operator: In
                values: ["zone-1", "zone-2", "zone-3"]
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values: ["config-server"]
              topologyKey: kubernetes.io/hostname
```

## Automation and CI/CD Integration

### GitOps Pipeline

Configure GitOps pipeline for configuration management:

```yaml
# .github/workflows/config-deploy.yml
name: Config Server Deployment
on:
  push:
    branches: [main]
    paths: ['config-server/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Java
      uses: actions/setup-java@v3
      with:
        java-version: '17'
        distribution: 'temurin'
    
    - name: Build and Test
      run: |
        cd config-server
        mvn clean verify
    
    - name: Security Scan
      run: |
        mvn org.owasp:dependency-check-maven:check
    
    - name: Build Docker Image
      run: |
        docker build -t ${{ secrets.DOCKER_REGISTRY }}/config-server:${{ github.sha }} .
        docker push ${{ secrets.DOCKER_REGISTRY }}/config-server:${{ github.sha }}
    
    - name: Deploy to Kubernetes
      run: |
        envsubst < k8s/deployment.yaml | kubectl apply -f -
      env:
        IMAGE_TAG: ${{ github.sha }}
```

### Infrastructure as Code

Terraform configuration for cloud resources:

```hcl
# terraform/config-server.tf
resource "aws_ecs_cluster" "config_server" {
  name = "config-server-cluster"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_service" "config_server" {
  name            = "config-server"
  cluster         = aws_ecs_cluster.config_server.id
  task_definition = aws_ecs_task_definition.config_server.arn
  desired_count   = 3
  
  deployment_configuration {
    maximum_percent         = 200
    minimum_healthy_percent = 100
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.config_server.arn
    container_name   = "config-server"
    container_port   = 8888
  }
}
```

## Security Hardening

### SSL/TLS Configuration

Generate production certificates:

```bash
# Generate private key
openssl genrsa -out config-server.key 2048

# Generate certificate signing request
openssl req -new -key config-server.key -out config-server.csr \
  -subj "/C=US/ST=State/L=City/O=Gogidix/OU=IT/CN=config-server.gogidix-ecommerce.com"

# Create PKCS12 keystore for Spring Boot
openssl pkcs12 -export -in config-server.crt -inkey config-server.key \
  -out config-server.p12 -name config-server -passout pass:${KEYSTORE_PASSWORD}
```

### OAuth2 Integration

Configure OAuth2 with Keycloak:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://keycloak.gogidix-ecommerce.com/auth/realms/gogidix
          jwk-set-uri: https://keycloak.gogidix-ecommerce.com/auth/realms/gogidix/protocol/openid-connect/certs
      client:
        registration:
          config-server:
            client-id: config-server
            client-secret: ${OAUTH2_CLIENT_SECRET}
            scope: openid,profile,email
        provider:
          keycloak:
            issuer-uri: https://keycloak.gogidix-ecommerce.com/auth/realms/gogidix
```

## Performance Optimization

### JVM Tuning for Production

```bash
# Production JVM arguments
JAVA_OPTS="
-server
-Xms2G
-Xmx4G
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+UseStringDeduplication
-XX:+UseCompressedOops
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/log/config-server/
-Xlog:gc*:file=/var/log/config-server/gc.log:time,uptime:filecount=10,filesize=100M
-Dspring.profiles.active=prod
-Dmanagement.endpoint.health.probes.enabled=true
-Djava.security.egd=file:/dev/./urandom
"
```

### Database Optimization

Configure PostgreSQL for optimal performance:

```sql
-- postgresql.conf optimizations
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
```

## Troubleshooting Setup Issues

### Common Setup Problems

1. **Git Authentication Failures**
   ```bash
   # Test Git access
   git ls-remote https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repo.git
   
   # Verify credentials
   echo $CONFIG_GIT_USERNAME
   echo $CONFIG_GIT_PASSWORD | base64
   ```

2. **SSL Certificate Issues**
   ```bash
   # Verify certificate
   keytool -list -v -keystore config-server.p12 -storepass ${KEYSTORE_PASSWORD}
   
   # Test SSL connection
   openssl s_client -connect config-server.gogidix-ecommerce.com:8888
   ```

3. **Service Discovery Problems**
   ```bash
   # Check Eureka registration
   curl -s http://eureka:8761/eureka/apps/CONFIG-SERVER | grep -o '<status>.*</status>'
   ```

## Next Steps

After completing the setup:

1. **Configuration Repository Setup**
   - Initialize configuration repository structure
   - Create environment-specific configurations
   - Set up branch protection rules
   - Configure automated testing for configuration changes

2. **Service Integration**
   - Configure client services to use Config Server
   - Set up service-specific configurations
   - Implement configuration refresh mechanisms
   - Configure feature toggles and A/B testing

3. **Security Implementation**
   - Configure encryption for sensitive properties
   - Set up OAuth2/OIDC integration
   - Implement audit logging
   - Configure certificate management

4. **Monitoring and Alerting**
   - Set up Prometheus metrics collection
   - Configure Grafana dashboards
   - Implement log aggregation
   - Set up alerting rules

5. **Operational Procedures**
   - Configure automated backup procedures
   - Set up disaster recovery procedures
   - Create runbooks for common operations
   - Document configuration standards for service teams

6. **Performance Tuning**
   - Optimize JVM settings
   - Configure connection pooling
   - Set up caching strategies
   - Implement load testing procedures
