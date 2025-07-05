# Configuration Server - Operations Guide

This comprehensive guide provides enterprise-grade operational procedures for maintaining, monitoring, and managing the Configuration Server in production environments across multiple regions and deployment scenarios.

## Executive Summary

This operations guide covers all aspects of Configuration Server operations including routine maintenance, monitoring, troubleshooting, disaster recovery, and compliance management. It is designed for DevOps engineers, SRE teams, and platform administrators responsible for maintaining high availability and security of centralized configuration services.

## Service Level Objectives (SLOs)

The Configuration Server operates under the following SLOs:

- **Availability**: 99.99% uptime (52.56 minutes downtime per year)
- **Response Time**: 95th percentile < 200ms for configuration retrieval
- **Error Rate**: < 0.1% of all requests
- **Configuration Propagation**: < 60 seconds from commit to service availability
- **Recovery Time Objective (RTO)**: 15 minutes for service restoration
- **Recovery Point Objective (RPO)**: 5 minutes maximum data loss

## Routine Operations

### Health Monitoring

Monitor the Configuration Server health using the following endpoints:

```bash
# Check overall health
curl -k https://config-server.gogidix-ecommerce.com/actuator/health

# Check specific health indicators
curl -k https://config-server.gogidix-ecommerce.com/actuator/health/git
curl -k https://config-server.gogidix-ecommerce.com/actuator/health/diskSpace
```

Set up regular health checks in your monitoring system (Prometheus/Grafana) with the following thresholds:

- Response time: < 500ms
- Error rate: < 0.1%
- Availability: > 99.9%

### Backup Procedures

#### Daily Configuration Backup

Schedule daily backups of the configuration repository:

```bash
# Clone the repository
git clone https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git

# Create a timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
cp -r configuration-repository backup/config_backup_${TIMESTAMP}

# Archive and compress backup
tar -czf backup/config_backup_${TIMESTAMP}.tar.gz backup/config_backup_${TIMESTAMP}

# Remove uncompressed backup
rm -rf backup/config_backup_${TIMESTAMP}

# Rotate backups (keep last 30 days)
find backup/ -name "config_backup_*.tar.gz" -type f -mtime +30 -delete
```

#### Database Backup

Back up the Config Server's internal database:

```bash
# For embedded H2 database
curl -k -X POST https://config-server.gogidix-ecommerce.com/actuator/h2-console/backup
```

### Log Management

#### Log Rotation

Configure log rotation in logback-spring.xml:

```xml
<configuration>
  <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/config-server.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>logs/config-server.%d{yyyy-MM-dd}.log</fileNamePattern>
      <maxHistory>30</maxHistory>
      <totalSizeCap>3GB</totalSizeCap>
    </rollingPolicy>
    <encoder>
      <pattern>%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n</pattern>
    </encoder>
  </appender>
  
  <root level="INFO">
    <appender-ref ref="FILE" />
  </root>
</configuration>
```

#### Log Analysis

Set up regular log analysis tasks:

1. Check for ERROR and WARN level messages
2. Monitor Git sync failures
3. Track authentication failures
4. Analyze response time patterns

### Performance Monitoring

Monitor the following metrics:

```bash
# Get all available metrics
curl -k https://config-server.gogidix-ecommerce.com/actuator/metrics

# Get specific metrics
curl -k https://config-server.gogidix-ecommerce.com/actuator/metrics/http.server.requests
curl -k https://config-server.gogidix-ecommerce.com/actuator/metrics/system.cpu.usage
curl -k https://config-server.gogidix-ecommerce.com/actuator/metrics/jvm.memory.used
```

Set up Grafana dashboards to monitor:

1. Request rate and latency
2. Error rate by endpoint
3. JVM memory usage
4. Git repository sync time
5. Thread pool utilization

### Capacity Planning

Monitor resource usage and plan for capacity increases:

1. CPU utilization should remain below 70% on average
2. Memory usage should stay below 80% of allocated JVM heap
3. Disk space for logs should have at least 20% free
4. Network bandwidth usage should be monitored for spikes

Plan to scale horizontally when:

- Average CPU utilization exceeds 60% for sustained periods
- Request latency increases by more than 20%
- Request rate approaches 80% of tested capacity

## Configuration Management

### Adding New Configuration Properties

Follow these steps to add new configuration properties:

1. Clone the configuration repository
   ```bash
   git clone https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git
   cd configuration-repository
   ```

2. Create or update the appropriate property file
   ```bash
   # For service-specific properties
   vim service-domains/social-commerce/product-service.yml
   
   # For environment-specific properties
   vim service-domains/social-commerce/product-service-prod.yml
   ```

3. Commit and push changes
   ```bash
   git add .
   git commit -m "Add new property configuration for product service"
   git push origin main
   ```

4. Verify the changes are available
   ```bash
   curl -k https://config-server.gogidix-ecommerce.com/product-service/prod
   ```

### Encrypting Sensitive Properties

To encrypt sensitive configuration values:

1. Use the encryption endpoint
   ```bash
   curl -k -X POST https://config-server.gogidix-ecommerce.com/encrypt -d 'sensitive-value'
   ```

2. Add the encrypted value to the configuration file
   ```yaml
   database:
     password: '{cipher}encrypted-value-returned-from-endpoint'
   ```

3. Verify encryption works correctly
   ```bash
   curl -k https://config-server.gogidix-ecommerce.com/product-service/prod
   # The value should be decrypted in the response
   ```

### Configuration Versioning

Manage configuration versions with Git tags:

```bash
# Tag a stable configuration version
git tag -a v1.2.0 -m "Stable configuration for release 1.2.0"
git push origin v1.2.0

# Access a specific version of configuration
curl -k https://config-server.gogidix-ecommerce.com/product-service/prod?label=v1.2.0
```

### Rolling Back Configurations

To roll back to a previous configuration version:

```bash
# Identify the commit to roll back to
git log --oneline

# Create a new commit that reverts to the previous state
git revert <commit-hash>

# Or reset to a specific tag
git reset --hard v1.1.0
git push -f origin main
```

Always notify service teams when rolling back configurations to ensure proper handling of changes.

## Troubleshooting

### Common Issues and Resolutions

#### Git Connectivity Issues

**Symptoms**:
- Error logs containing "Could not fetch remote for master"
- Configuration not updating
- Health check failing for Git repository

**Resolution**:
1. Verify network connectivity
   ```bash
   ping github.com
   curl -v https://github.com
   ```

2. Check Git credentials
   ```bash
   # Verify environment variables
   echo $SPRING_CLOUD_CONFIG_SERVER_GIT_USERNAME
   ```

3. Test Git connection manually
   ```bash
   git clone https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository.git
   ```

4. Restart the Config Server if credentials are updated
   ```bash
   kubectl rollout restart deployment config-server
   ```

#### High Memory Usage

**Symptoms**:
- JVM memory metrics approaching limits
- GC overhead high
- Occasional OutOfMemoryError exceptions

**Resolution**:
1. Adjust JVM memory settings
   ```
   -Xms1G -Xmx2G -XX:+UseG1GC
   ```

2. Optimize Git clone settings
   ```yaml
   spring:
     cloud:
       config:
         server:
           git:
             clone-on-start: false
             force-pull: true
             timeout: 30
   ```

3. Implement caching improvements
   ```yaml
   spring:
     cache:
       type: caffeine
       caffeine:
         spec: maximumSize=1000,expireAfterWrite=60s
   ```

#### High Response Latency

**Symptoms**:
- Slow response times
- Increasing request queue depth
- Timeouts from client services

**Resolution**:
1. Check database connection pool settings
   ```yaml
   spring:
     datasource:
       hikari:
         maximum-pool-size: 20
         minimum-idle: 5
         connection-timeout: 30000
   ```

2. Optimize Git repository access
   ```yaml
   spring:
     cloud:
       config:
         server:
           git:
             default-label: main
             search-paths: '{application}'
   ```

3. Add or increase thread pool size
   ```yaml
   server:
     tomcat:
       threads:
         max: 200
         min-spare: 20
   ```

4. Implement or adjust caching
   ```yaml
   spring:
     cloud:
       config:
         server:
           git:
             refresh-rate: 60
   ```

### Diagnostic Procedures

#### Memory Leak Investigation

If memory usage keeps increasing over time:

1. Enable verbose GC logging
   ```
   -Xlog:gc*:file=gc.log:time,uptime:filecount=5,filesize=10M
   ```

2. Collect heap dumps
   ```bash
   # Via JMX
   jmap -dump:format=b,file=heap_dump.bin <PID>
   
   # Via actuator endpoint
   curl -k -X POST https://config-server.gogidix-ecommerce.com/actuator/heapdump > heap_dump.bin
   ```

3. Analyze heap dumps with tools like Eclipse Memory Analyzer (MAT)

#### Performance Analysis

For performance issues:

1. Collect thread dumps
   ```bash
   # Via JMX
   jstack <PID> > thread_dump.txt
   
   # Via actuator endpoint
   curl -k https://config-server.gogidix-ecommerce.com/actuator/threaddump > thread_dump.txt
   ```

2. Analyze thread states for blocked or waiting threads

3. Enable trace logging temporarily
   ```yaml
   logging:
     level:
       org.springframework.cloud.config: TRACE
       org.springframework.web: DEBUG
   ```

#### Configuration Issue Diagnosis

If services report configuration issues:

1. Verify configuration exists
   ```bash
   curl -k https://config-server.gogidix-ecommerce.com/product-service/prod
   ```

2. Check configuration values in Git repository
   ```bash
   git show origin/main:service-domains/social-commerce/product-service-prod.yml
   ```

3. Verify client service configuration
   ```yaml
   spring:
     cloud:
       config:
         uri: https://config-server.gogidix-ecommerce.com
         fail-fast: true
   ```

### Emergency Procedures

#### Service Restart

If the Config Server needs to be restarted:

```bash
# For Kubernetes deployment
kubectl rollout restart deployment config-server

# For Docker Compose deployment
docker-compose restart config-server
```

#### Fallback to Static Configuration

In case of persistent configuration service failure:

1. Notify all service teams to switch to local configuration
2. Update client services to disable config server
   ```yaml
   spring:
     cloud:
       config:
         enabled: false
   ```

3. Deploy emergency static configurations to each service

#### Data Recovery

To recover from data corruption:

1. Stop the Configuration Server
   ```bash
   kubectl scale deployment config-server --replicas=0
   ```

2. Restore from backup
   ```bash
   # Extract backup
   tar -xzf backup/config_backup_${TIMESTAMP}.tar.gz
   
   # Push to Git repository
   cd backup/config_backup_${TIMESTAMP}
   git push -f origin main
   ```

3. Restart the Configuration Server
   ```bash
   kubectl scale deployment config-server --replicas=3
   ```

## Maintenance Procedures

### Routine Maintenance

#### JVM Tuning

Periodically review and adjust JVM settings:

```
# Recommended production settings
-server
-Xms2G
-Xmx2G
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/var/log/config-server/heap-dump.hprof
-Xlog:gc*:file=/var/log/config-server/gc.log:time,uptime:filecount=10,filesize=100M
-Dspring.profiles.active=prod
```

#### Connection Pool Optimization

Review and optimize database connection pool settings:

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      idle-timeout: 600000
      max-lifetime: 1800000
```

#### Log Cleanup

Set up automated log cleanup:

```bash
# Delete logs older than 30 days
find /var/log/config-server -name "*.log.*" -type f -mtime +30 -delete
```

### Scheduled Maintenance

Plan maintenance windows for:

1. OS and JDK updates
2. Spring Boot and Spring Cloud upgrades
3. Security patches
4. Database maintenance
5. Certificate renewals

Announce maintenance windows at least 72 hours in advance.

### Upgrade Procedures

#### Minor Version Upgrade

For minor version upgrades:

1. Update dependencies in pom.xml
   ```xml
   <parent>
       <groupId>org.springframework.boot</groupId>
       <artifactId>spring-boot-starter-parent</artifactId>
       <version>3.1.x</version>
   </parent>
   ```

2. Build and test in development environment
   ```bash
   mvn clean package
   ```

3. Deploy to staging environment
   ```bash
   kubectl apply -f k8s/staging/
   ```

4. Run validation tests
   ```bash
   ./run-integration-tests.sh staging
   ```

5. Deploy to production with rolling update
   ```bash
   kubectl apply -f k8s/production/
   ```

#### Major Version Upgrade

For major version upgrades:

1. Create a parallel deployment with the new version
2. Migrate configuration repository if needed
3. Test compatibility with all services
4. Gradually shift traffic from old to new version
5. Monitor for issues during transition
6. Complete cutover after validation

### Certificate Management

#### Certificate Renewal

Renew SSL certificates before expiration:

1. Generate Certificate Signing Request (CSR)
   ```bash
   keytool -certreq -alias config-server -keystore config-server.p12 -file config-server.csr
   ```

2. Submit CSR to Certificate Authority

3. Import signed certificate
   ```bash
   keytool -importcert -alias config-server -file signed_cert.pem -keystore config-server.p12
   ```

4. Update Kubernetes secret
   ```bash
   kubectl create secret tls config-server-tls --key=key.pem --cert=cert.pem --dry-run=client -o yaml | kubectl apply -f -
   ```

5. Restart the service to apply new certificate
   ```bash
   kubectl rollout restart deployment config-server
   ```

## Disaster Recovery

### Recovery Point Objective (RPO)

The Configuration Server has an RPO of 15 minutes, meaning data loss should not exceed 15 minutes in a disaster scenario.

### Recovery Time Objective (RTO)

The Configuration Server has an RTO of 30 minutes, meaning service should be restored within 30 minutes of a disaster.

### Disaster Recovery Process

1. **Assessment**:
   - Determine the nature and scope of the disaster
   - Identify affected components
   - Evaluate data loss potential

2. **Service Restoration**:
   - Activate standby region if primary region is down
   - Redirect traffic to operational instances
   - Deploy new instances if necessary

3. **Data Recovery**:
   - Restore configuration from Git repository
   - Verify configuration integrity
   - Restore database from latest backup if needed

4. **Validation**:
   - Verify service health
   - Test configuration retrieval for key services
   - Validate security and encryption functionality

5. **Communication**:
   - Notify all service teams of recovery status
   - Provide guidance on client-side recovery actions
   - Update status dashboard

### Cross-Region Failover

For multi-region deployments, configure automatic failover:

1. Use global load balancer with health checks
2. Configure client services with multiple config server URLs
3. Set up cross-region configuration replication

## Security Operations

### Access Management

#### User Access Review

Conduct quarterly access reviews:

1. Review all users with access to:
   - Configuration repository
   - Config Server management endpoints
   - Encryption keys

2. Remove unnecessary access
3. Update credentials for service accounts
4. Verify OAuth2 client registrations

#### Credential Rotation

Rotate the following credentials every 90 days:

1. Git repository credentials
2. Encryption keys
3. TLS certificates (if not managed by automatic renewal)
4. Database credentials

### Security Monitoring

Monitor for security events:

1. Failed authentication attempts
2. Unusual access patterns
3. Configuration changes outside business hours
4. Attempts to access sensitive endpoints

Configure alerts for security events:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: auditevents
  auditevents:
    enabled: true
```

### Security Updates

Apply security updates according to this prioritization:

1. Critical vulnerabilities: Within 24 hours
2. High vulnerabilities: Within 1 week
3. Medium vulnerabilities: During next maintenance window
4. Low vulnerabilities: During next major update

## Compliance and Auditing

### Audit Log Management

Configure detailed audit logging:

```yaml
logging:
  level:
    org.springframework.security: INFO
    org.springframework.security.access: INFO
    org.springframework.security.authentication: INFO
    org.springframework.security.authorization: INFO
```

Ensure audit logs capture:

1. All configuration changes (who, what, when)
2. All access to sensitive configurations
3. All encryption/decryption operations
4. Administrative actions

### Compliance Reporting

Generate monthly compliance reports including:

1. Service availability metrics
2. Security incident summary
3. Configuration change summary
4. Access control changes
5. Encryption key rotation status

### Regulatory Requirements

Ensure the Configuration Server meets:

1. PCI DSS requirements for configuration management
2. GDPR requirements for sensitive data protection
3. ISO 27001 requirements for information security
4. SOC 2 requirements for availability and security

## Performance Tuning

### JVM Tuning

Optimize JVM garbage collection:

```
# For high throughput
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=8m

# For low latency
-XX:+UseZGC
-XX:ZAllocationSpikeTolerance=2.0
```

### Application Tuning

Optimize application parameters:

```yaml
server:
  tomcat:
    max-threads: 200
    min-spare-threads: 20
    max-connections: 8192
    accept-count: 100

spring:
  cloud:
    config:
      server:
        git:
          timeout: 30
          clone-on-start: true
          force-pull: true
```

### Database Tuning

Optimize database connection pool:

```yaml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
      minimum-idle: 10
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
```

### Cache Optimization

Implement multi-level caching:

```yaml
spring:
  cache:
    type: caffeine
    caffeine:
      spec: maximumSize=1000,expireAfterWrite=60s
```

## Monitoring and Alerting

### Key Performance Indicators

Monitor these KPIs:

1. **Availability**: Target 99.99% uptime
2. **Response Time**: 95th percentile < 200ms
3. **Error Rate**: < 0.1% of requests
4. **Configuration Freshness**: < 60 seconds from commit to availability

### Alert Configuration

Configure alerts for:

1. Service unavailability (30 seconds)
2. High error rates (> 1% for 5 minutes)
3. Response time degradation (> 500ms for 5 minutes)
4. Memory usage (> 85% for 10 minutes)
5. Git sync failures (3 consecutive failures)

### Dashboard Setup

Set up Grafana dashboards for:

1. Service health overview
2. Request metrics (volume, latency, errors)
3. Resource utilization (CPU, memory, disk)
4. Configuration activity (requests, updates)
5. Security events

## Runbooks

### Service Restart Runbook

1. **Notification**: Inform service teams of planned restart
2. **Pre-checks**: Verify client services have cached configurations
3. **Execution**:
   ```bash
   kubectl rollout restart deployment config-server
   ```
4. **Verification**: Check health endpoints after restart
5. **Rollback**: If issues occur, revert to previous version

### Configuration Refresh Runbook

1. **Verification**: Confirm changes in Git repository
2. **Execution**:
   ```bash
   curl -k -X POST https://config-server.gogidix-ecommerce.com/actuator/busrefresh
   ```
3. **Validation**: Verify new configuration is available
4. **Notification**: Inform service teams of configuration update

### Key Rotation Runbook

1. **Preparation**: Generate new encryption key
   ```bash
   openssl genrsa -out new-encryption.pem 2048
   ```
2. **Backup**: Take a backup of all encrypted properties
3. **Re-encryption**: Re-encrypt all sensitive properties with new key
4. **Deployment**: Update the key in the Config Server
5. **Verification**: Test decryption with new key
6. **Cleanup**: Securely delete old key material

## SLA and Service Metrics

### Service Level Objectives

The Configuration Server has the following SLOs:

1. **Availability**: 99.99% uptime
2. **Latency**: 95th percentile < 200ms
3. **Error Rate**: < 0.1% of requests

### Monitoring Metrics

Track the following metrics for SLA reporting:

1. **Request Count**: Total requests per endpoint
2. **Error Count**: Failed requests by error type
3. **Response Time**: Average, 95th percentile, 99th percentile
4. **Availability**: Percentage of successful health checks

### Reporting

Generate weekly SLA reports including:

1. Availability percentage
2. Response time statistics
3. Error rate statistics
4. Incident summary
5. Maintenance activities

## Appendix

### Useful Commands

```bash
# Get service status
kubectl get pods -l app=config-server

# View logs
kubectl logs -l app=config-server --tail=100

# Check endpoints
curl -k https://config-server.gogidix-ecommerce.com/actuator/health
curl -k https://config-server.gogidix-ecommerce.com/actuator/info
curl -k https://config-server.gogidix-ecommerce.com/actuator/env

# Test configuration retrieval
curl -k https://config-server.gogidix-ecommerce.com/application/default
curl -k https://config-server.gogidix-ecommerce.com/product-service/prod

# Force configuration refresh
curl -k -X POST https://config-server.gogidix-ecommerce.com/actuator/busrefresh

# Encrypt/decrypt values
curl -k -X POST https://config-server.gogidix-ecommerce.com/encrypt -d 'value-to-encrypt'
curl -k -X POST https://config-server.gogidix-ecommerce.com/decrypt -d '{cipher}encrypted-value'
```

### Enterprise Operations Procedures

### Change Management

Follow enterprise change management procedures for all configuration updates:

1. **Change Request Process**
   ```bash
   # Create change request in ServiceNow
   curl -X POST "https://servicenow.gogidix-ecommerce.com/api/now/table/change_request" \
     -H "Authorization: Bearer ${SERVICENOW_TOKEN}" \
     -H "Content-Type: application/json" \
     -d '{
       "short_description": "Config Server Update",
       "description": "Update configuration for production environment",
       "category": "Software",
       "priority": "3",
       "risk": "Low"
     }'
   ```

2. **Configuration Validation Pipeline**
   ```yaml
   # .github/workflows/config-validation.yml
   name: Configuration Validation
   on:
     pull_request:
       branches: [main]
       paths: ['configs/**']
   
   jobs:
     validate:
       runs-on: ubuntu-latest
       steps:
       - uses: actions/checkout@v3
       
       - name: Validate YAML Syntax
         run: |
           find configs -name "*.yml" -exec yamllint {} \;
       
       - name: Security Scan
         run: |
           # Scan for secrets and sensitive data
           truffleHog --regex --entropy=False .
       
       - name: Configuration Drift Detection
         run: |
           # Compare with production baseline
           ./scripts/config-drift-check.sh
       
       - name: Impact Analysis
         run: |
           # Analyze configuration changes impact
           ./scripts/impact-analysis.sh
   ```

### Configuration Lifecycle Management

1. **Configuration Versioning Strategy**
   ```bash
   # Semantic versioning for configuration releases
   git tag -a config-v1.2.3 -m "Configuration release v1.2.3"
   git push origin config-v1.2.3
   
   # Branch strategy for environments
   git checkout -b release/production-2024-01
   git merge develop
   git push origin release/production-2024-01
   ```

2. **Configuration Rollout Strategy**
   ```bash
   # Gradual rollout process
   # Stage 1: Canary (5% of traffic)
   kubectl patch virtualservice config-server-vs --patch '
   spec:
     http:
     - route:
       - destination:
           host: config-server
           subset: stable
         weight: 95
       - destination:
           host: config-server
           subset: canary
         weight: 5
   '
   
   # Stage 2: Progressive rollout (25%, 50%, 100%)
   # Automated rollout based on success metrics
   ```

### Multi-Region Operations

1. **Cross-Region Configuration Sync**
   ```bash
   # Automated sync between regions
   #!/bin/bash
   # sync-regions.sh
   
   REGIONS=("europe" "africa")
   SOURCE_REGION="europe"
   
   for region in "${REGIONS[@]}"; do
     if [ "$region" != "$SOURCE_REGION" ]; then
       echo "Syncing configuration to $region"
       
       # Sync Git repositories
       git clone https://github.com/config-${SOURCE_REGION}.git
       cd config-${SOURCE_REGION}
       git remote add $region https://github.com/config-${region}.git
       git push $region main
       
       # Trigger config refresh in target region
       curl -X POST "https://config-server-${region}.gogidix-ecommerce.com/actuator/busrefresh"
     fi
   done
   ```

2. **Region-Specific Health Checks**
   ```bash
   # Health check across all regions
   #!/bin/bash
   # multi-region-health.sh
   
   REGIONS=("europe-west-1" "africa-south-1")
   
   for region in "${REGIONS[@]}"; do
     echo "Checking health for region: $region"
     
     response=$(curl -s -o /dev/null -w "%{http_code}" \
       "https://config-server-${region}.gogidix-ecommerce.com/actuator/health")
     
     if [ "$response" -eq 200 ]; then
       echo "✓ $region is healthy"
     else
       echo "✗ $region is unhealthy (HTTP $response)"
       # Trigger alert
       ./scripts/alert-region-failure.sh $region
     fi
   done
   ```

### Advanced Monitoring and Observability

1. **Distributed Tracing Integration**
   ```yaml
   # application-prod.yml
   spring:
     zipkin:
       base-url: https://zipkin.gogidix-ecommerce.com
     sleuth:
       sampler:
         probability: 0.1
       zipkin:
         enabled: true
   
   management:
     tracing:
       sampling:
         probability: 0.1
   ```

2. **Custom Metrics and Dashboards**
   ```java
   // Custom metrics for configuration operations
   @Component
   public class ConfigServerMetrics {
       
       private final MeterRegistry meterRegistry;
       private final Counter configRetrievalCounter;
       private final Timer configRetrievalTimer;
       
       public ConfigServerMetrics(MeterRegistry meterRegistry) {
           this.meterRegistry = meterRegistry;
           this.configRetrievalCounter = Counter.builder("config.retrieval.count")
               .description("Number of configuration retrievals")
               .tag("service", "config-server")
               .register(meterRegistry);
           this.configRetrievalTimer = Timer.builder("config.retrieval.duration")
               .description("Configuration retrieval duration")
               .register(meterRegistry);
       }
   }
   ```

3. **Synthetic Monitoring**
   ```bash
   # Synthetic monitoring script
   #!/bin/bash
   # synthetic-monitor.sh
   
   CONFIG_SERVER_URL="https://config-server.gogidix-ecommerce.com"
   TEST_SERVICE="product-service"
   TEST_PROFILE="prod"
   
   # Test configuration retrieval
   start_time=$(date +%s%N)
   response=$(curl -s -w "%{http_code}" \
     "${CONFIG_SERVER_URL}/${TEST_SERVICE}/${TEST_PROFILE}")
   end_time=$(date +%s%N)
   
   duration=$(( (end_time - start_time) / 1000000 ))
   
   if [[ $response == *"200"* ]] && [[ $duration -lt 500 ]]; then
     echo "Synthetic test PASSED: ${duration}ms"
   else
     echo "Synthetic test FAILED: ${response}, ${duration}ms"
     # Send alert
     curl -X POST "https://alerts.gogidix-ecommerce.com/webhook" \
       -d "{'alert': 'config-server-synthetic-test-failed', 'duration': $duration}"
   fi
   ```

### Security Operations

1. **Security Scanning Automation**
   ```bash
   # Automated security scanning
   #!/bin/bash
   # security-scan.sh
   
   # Container security scan
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     -v $(pwd):/app aquasec/trivy image config-server:latest
   
   # Configuration security scan
   checkov --framework dockerfile --file Dockerfile
   
   # Dependency vulnerability scan
   mvn org.owasp:dependency-check-maven:check
   
   # Secret detection
   truffleHog --regex --entropy=False .
   ```

2. **Certificate Management Automation**
   ```bash
   # Automated certificate renewal
   #!/bin/bash
   # cert-renewal.sh
   
   CERT_PATH="/etc/ssl/certs/config-server"
   DAYS_BEFORE_EXPIRY=30
   
   # Check certificate expiry
   expiry_date=$(openssl x509 -in ${CERT_PATH}.crt -noout -enddate | cut -d= -f2)
   expiry_epoch=$(date -d "$expiry_date" +%s)
   current_epoch=$(date +%s)
   days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
   
   if [ $days_left -lt $DAYS_BEFORE_EXPIRY ]; then
     echo "Certificate expires in $days_left days, renewing..."
     
     # Generate new certificate using Let's Encrypt
     certbot renew --cert-name config-server.gogidix-ecommerce.com
     
     # Update Kubernetes secret
     kubectl create secret tls config-server-tls \
       --cert=${CERT_PATH}.crt \
       --key=${CERT_PATH}.key \
       --dry-run=client -o yaml | kubectl apply -f -
     
     # Restart pods to pick up new certificate
     kubectl rollout restart deployment config-server
   fi
   ```

### Capacity Management

1. **Auto-Scaling Configuration**
   ```yaml
   # hpa-advanced.yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: config-server-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: config-server
     minReplicas: 3
     maxReplicas: 20
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
     - type: Resource
       resource:
         name: memory
         target:
           type: Utilization
           averageUtilization: 80
     - type: Pods
       pods:
         metric:
           name: http_requests_per_second
         target:
           type: AverageValue
           averageValue: "50"
     behavior:
       scaleUp:
         stabilizationWindowSeconds: 60
         policies:
         - type: Percent
           value: 50
           periodSeconds: 60
       scaleDown:
         stabilizationWindowSeconds: 300
         policies:
         - type: Percent
           value: 10
           periodSeconds: 60
   ```

2. **Predictive Scaling**
   ```python
   # predictive-scaling.py
   import pandas as pd
   from sklearn.linear_model import LinearRegression
   import numpy as np
   
   def predict_load():
       # Historical load data
       df = pd.read_csv('config_server_metrics.csv')
       
       # Feature engineering
       df['hour'] = pd.to_datetime(df['timestamp']).dt.hour
       df['day_of_week'] = pd.to_datetime(df['timestamp']).dt.dayofweek
       
       # Train model
       X = df[['hour', 'day_of_week', 'request_rate']]
       y = df['cpu_utilization']
       
       model = LinearRegression()
       model.fit(X, y)
       
       # Predict next hour load
       next_hour = datetime.now().hour + 1
       day_of_week = datetime.now().weekday()
       current_rate = get_current_request_rate()
       
       predicted_cpu = model.predict([[next_hour, day_of_week, current_rate]])
       
       # Scale if predicted load > 70%
       if predicted_cpu > 70:
           scale_up_instances()
   ```

### Data Protection and Privacy

1. **GDPR Compliance Procedures**
   ```bash
   # GDPR data handling procedures
   #!/bin/bash
   # gdpr-compliance.sh
   
   # Encrypt personal data in configurations
   encrypt_personal_data() {
     local config_file=$1
     
     # Identify personal data patterns
     grep -E "(email|phone|address)" $config_file | while read line; do
       # Encrypt using GPG
       encrypted=$(echo "$line" | gpg --encrypt --armor -r config-server@gogidix.com)
       # Replace in file
       sed -i "s/$line/$encrypted/" $config_file
     done
   }
   
   # Data retention policy enforcement
   cleanup_old_configs() {
     find /var/log/config-server -name "*.log" -mtime +2555 -delete  # 7 years
     find /backup/configs -name "*.tar.gz" -mtime +2555 -delete
   }
   ```

2. **Data Anonymization**
   ```yaml
   # Data anonymization configuration
   spring:
     profiles:
       active: anonymize
   
   anonymization:
     enabled: true
     patterns:
       - field: "email"
         strategy: "hash"
       - field: "phone"
         strategy: "mask"
       - field: "address"
         strategy: "generalize"
   ```

### Business Continuity Planning

1. **Disaster Recovery Automation**
   ```bash
   # Automated disaster recovery
   #!/bin/bash
   # disaster-recovery.sh
   
   DR_REGION="africa-south-1"
   PRIMARY_REGION="europe-west-1"
   
   detect_disaster() {
     # Check primary region health
     health_check=$(curl -s -o /dev/null -w "%{http_code}" \
       "https://config-server-${PRIMARY_REGION}.gogidix-ecommerce.com/actuator/health")
     
     if [ "$health_check" != "200" ]; then
       return 1  # Disaster detected
     fi
     return 0
   }
   
   failover_to_dr() {
     echo "Initiating failover to DR region: $DR_REGION"
     
     # Update DNS to point to DR region
     aws route53 change-resource-record-sets \
       --hosted-zone-id Z123456789 \
       --change-batch file://dns-failover.json
     
     # Scale up DR region
     kubectl --context=$DR_REGION scale deployment config-server --replicas=5
     
     # Notify stakeholders
     send_notification "Config Server failed over to $DR_REGION"
   }
   ```

2. **Backup Verification**
   ```bash
   # Automated backup verification
   #!/bin/bash
   # verify-backups.sh
   
   BACKUP_DIR="/backup/config-server"
   TEST_RESTORE_DIR="/tmp/restore-test"
   
   verify_backup() {
     local backup_file=$1
     
     # Extract backup
     mkdir -p $TEST_RESTORE_DIR
     tar -xzf $backup_file -C $TEST_RESTORE_DIR
     
     # Verify integrity
     if [ -f "$TEST_RESTORE_DIR/application.yml" ]; then
       echo "✓ Backup verification successful: $backup_file"
       return 0
     else
       echo "✗ Backup verification failed: $backup_file"
       return 1
     fi
     
     # Cleanup
     rm -rf $TEST_RESTORE_DIR
   }
   
   # Verify all backups
   for backup in $BACKUP_DIR/*.tar.gz; do
     verify_backup $backup
   done
   ```

## Reference Documents

- [Spring Cloud Config Server Documentation](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)
- [Kubernetes Deployment Guide](../setup/kubernetes-deployment.md)
- [Security Compliance Requirements](../security/compliance-requirements.md)
- [Disaster Recovery Plan](../disaster-recovery/config-server-dr-plan.md)
- [Monitoring Setup Guide](../monitoring/prometheus-grafana-setup.md)
- [Configuration Management Standards](../standards/config-management-standards.md)
- [Incident Response Procedures](../incident-response/config-server-incidents.md)
- [Capacity Planning Guidelines](../capacity/planning-guidelines.md)
- [Security Operations Runbook](../security/security-operations.md)
