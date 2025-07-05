# Database Migrations - Operations Guide

This guide provides operational procedures for maintaining and managing the Database Migrations service across the Social E-commerce Ecosystem.

## Routine Operations

### Migration Management

#### Creating New Migrations

Follow these steps to create a new migration:

1. **Identify the appropriate domain and technology**:
   ```
   Domain: social-commerce, warehousing, courier-services, centralized-dashboard
   Technology: postgresql, mongodb, redis, elasticsearch
   ```

2. **Create migration script in the appropriate directory**:
   ```bash
   # For PostgreSQL migrations in Social Commerce domain
   cd src/main/resources/db/migration/postgresql/social-commerce
   
   # Create migration file with correct naming convention
   # Format: V{major}_{minor}_{patch}__{description}.sql
   touch V1_2_0__add_product_categories.sql
   ```

3. **Write migration content following best practices**:
   ```sql
   -- Migration: Add product categories to social commerce
   
   -- Create categories table
   CREATE TABLE IF NOT EXISTS social_commerce.product_categories (
     id SERIAL PRIMARY KEY,
     name VARCHAR(100) NOT NULL,
     description TEXT,
     parent_id INTEGER REFERENCES product_categories(id),
     created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
     updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
   );
   
   -- Create index on parent_id for faster hierarchy lookups
   CREATE INDEX idx_product_categories_parent_id ON social_commerce.product_categories(parent_id);
   
   -- Add category_id to products table
   ALTER TABLE social_commerce.products 
   ADD COLUMN category_id INTEGER REFERENCES product_categories(id);
   
   -- Create index on category_id
   CREATE INDEX idx_products_category_id ON social_commerce.products(category_id);
   
   -- Create trigger for updated_at timestamp
   CREATE TRIGGER update_product_categories_timestamp
   BEFORE UPDATE ON social_commerce.product_categories
   FOR EACH ROW
   EXECUTE FUNCTION update_timestamp();
   ```

4. **Test migration locally**:
   ```bash
   # Run migration validation
   ./mvnw verify -Pmigration-validate -Dmigration.environment=development -Dmigration.domain=social-commerce
   
   # Execute migration in development environment
   ./mvnw verify -Pmigration-execute -Dmigration.environment=development -Dmigration.domain=social-commerce
   ```

5. **Document the migration**:
   ```bash
   # Create migration documentation
   cat > docs/migrations/social-commerce/V1_2_0__add_product_categories.md << EOF
   # Product Categories Migration
   
   ## Purpose
   
   This migration adds product categorization capabilities to the Social Commerce domain.
   
   ## Changes
   
   - Creates product_categories table with hierarchical structure
   - Adds category_id to products table
   - Creates necessary indexes and constraints
   
   ## Impact
   
   - No data modifications
   - Adds new capabilities for product categorization
   - Enables future filtering and navigation features
   
   ## Dependencies
   
   - Requires V1_0_0__initial_schema.sql
   
   ## Rollback Procedure
   
   ```sql
   ALTER TABLE social_commerce.products DROP COLUMN category_id;
   DROP TABLE social_commerce.product_categories;
   ```
   EOF
   ```

6. **Commit and push changes**:
   ```bash
   git add src/main/resources/db/migration/postgresql/social-commerce/V1_2_0__add_product_categories.sql docs/migrations/social-commerce/V1_2_0__add_product_categories.md
   git commit -m "feat(social-commerce): Add product categories"
   git push origin feature/product-categories
   ```

#### Executing Migrations

Execute migrations through different methods depending on the environment:

1. **Development Environment** (automatic):
   ```bash
   # Migrations execute automatically on application startup
   java -jar target/database-migrations-1.0.0.jar
   ```

2. **Testing Environment** (via API):
   ```bash
   # Execute migrations via API
   curl -X POST "http://localhost:8080/api/v1/migrations/execute" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "environment": "testing",
       "domain": "social-commerce",
       "version": "1.2.0"
     }'
   ```

3. **Staging Environment** (via CI/CD):
   ```bash
   # Trigger GitHub Actions workflow
   gh workflow run database-migration.yml -F environment=staging -F domain=social-commerce -F version=1.2.0
   ```

4. **Production Environment** (scheduled via CI/CD):
   ```bash
   # Schedule migration execution during maintenance window
   gh workflow run database-migration.yml \
     -F environment=production \
     -F domain=social-commerce \
     -F version=1.2.0 \
     -F scheduled=true \
     -F schedule-time="2023-06-25T01:00:00Z"
   ```

#### Verifying Migration Status

Check migration status to ensure proper execution:

```bash
# Check migration status via API
curl -X GET "http://localhost:8080/api/v1/migrations/status?domain=social-commerce&environment=production" \
  -H "Authorization: Bearer ${TOKEN}"

# Expected response
{
  "domain": "social-commerce",
  "environment": "production",
  "current_version": "1.2.0",
  "migrations": [
    {
      "version": "1.0.0",
      "description": "initial_schema",
      "type": "postgresql",
      "executed_at": "2023-05-10T08:30:00Z",
      "execution_time": 1250,
      "status": "SUCCESS"
    },
    {
      "version": "1.1.0",
      "description": "add_product_reviews",
      "type": "postgresql",
      "executed_at": "2023-05-25T09:15:00Z",
      "execution_time": 890,
      "status": "SUCCESS"
    },
    {
      "version": "1.2.0",
      "description": "add_product_categories",
      "type": "postgresql",
      "executed_at": "2023-06-15T02:10:00Z",
      "execution_time": 1120,
      "status": "SUCCESS"
    }
  ],
  "pending_migrations": []
}
```

### Database Maintenance

#### Health Checks

Regularly check the health of the database migration service:

```bash
# Check service health
curl -X GET "http://localhost:8080/actuator/health" \
  -H "Authorization: Bearer ${TOKEN}"

# Expected response
{
  "status": "UP",
  "components": {
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    },
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 10737418240,
        "free": 5368709120,
        "threshold": 10485760,
        "exists": true
      }
    },
    "mongo": {
      "status": "UP",
      "details": {
        "version": "5.0.6"
      }
    },
    "redis": {
      "status": "UP",
      "details": {
        "version": "6.2.6"
      }
    },
    "elasticsearch": {
      "status": "UP",
      "details": {
        "version": "7.16.2"
      }
    }
  }
}
```

#### Schema Validation

Validate database schemas regularly to ensure integrity:

```bash
# Validate all schemas
./mvnw verify -Pmigration-validate -Dmigration.environment=production -Dmigration.domain=all

# Validate specific domain schema
./mvnw verify -Pmigration-validate -Dmigration.environment=production -Dmigration.domain=social-commerce
```

#### Performance Monitoring

Monitor migration performance metrics:

```bash
# Get performance metrics
curl -X GET "http://localhost:8080/actuator/metrics/migration.execution" \
  -H "Authorization: Bearer ${TOKEN}"

# Expected response
{
  "name": "migration.execution",
  "description": "Migration execution time",
  "baseUnit": "milliseconds",
  "measurements": [
    {
      "statistic": "COUNT",
      "value": 24
    },
    {
      "statistic": "TOTAL",
      "value": 28560
    },
    {
      "statistic": "MAX",
      "value": 3250
    }
  ],
  "availableTags": [
    {
      "tag": "domain",
      "values": [
        "social-commerce",
        "warehousing",
        "courier-services",
        "centralized-dashboard"
      ]
    },
    {
      "tag": "environment",
      "values": [
        "development",
        "testing",
        "staging",
        "production"
      ]
    },
    {
      "tag": "status",
      "values": [
        "success",
        "failed"
      ]
    }
  ]
}
```

### Log Management

#### Accessing Logs

Access and analyze migration logs:

```bash
# View service logs
cat logs/migrations.log | grep "Migration executed"

# Filter logs by domain
cat logs/migrations.log | grep "social-commerce"

# Filter logs by status
cat logs/migrations.log | grep "FAILED"

# View logs from Kubernetes
kubectl logs -l app=database-migrations -n central-configuration
```

#### Log Rotation

Configure log rotation to manage log file sizes:

```bash
# Check current log rotation configuration
cat config/logback-spring.xml

# Configure logback for rotation
cat > config/logback-spring.xml << EOF
<configuration>
  <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
    <file>logs/migrations.log</file>
    <rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
      <fileNamePattern>logs/migrations.%d{yyyy-MM-dd}.log</fileNamePattern>
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
EOF
```

#### Centralized Logging

Configure integration with centralized logging system:

```yaml
# Filebeat configuration for ELK stack integration
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /path/to/logs/migrations.log
  fields:
    service: database-migrations
    environment: production
  multiline:
    pattern: '^[0-9]{4}-[0-9]{2}-[0-9]{2}'
    negate: true
    match: after

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "database-migrations-%{+yyyy.MM.dd}"
```

## Troubleshooting

### Common Issues and Resolutions

#### Migration Failures

**Issue**: Migration script fails to execute
**Resolution**:

1. Check migration logs for specific error messages:
   ```bash
   cat logs/migrations.log | grep "Migration failed"
   ```

2. Verify database connectivity:
   ```bash
   # PostgreSQL
   psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1"
   
   # MongoDB
   mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} --authenticationDatabase admin --eval "db.version()"
   ```

3. Check script syntax for errors:
   ```bash
   # PostgreSQL
   cat src/main/resources/db/migration/postgresql/social-commerce/V1_2_0__add_product_categories.sql | \
     psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -v ON_ERROR_STOP=1 -f -
   
   # MongoDB
   mongo --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} \
     --authenticationDatabase admin --eval "load('src/main/resources/db/migration/mongodb/warehousing/V1_2_0__add_storage_types.js')"
   ```

4. Verify user permissions:
   ```sql
   -- PostgreSQL: Check permissions
   SELECT grantee, privilege_type 
   FROM information_schema.role_table_grants 
   WHERE table_name = 'products';
   ```

5. Fix the issue and manually mark the migration as resolved if necessary:
   ```bash
   # Using the migration API
   curl -X POST "http://localhost:8080/api/v1/migrations/repair" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "domain": "social-commerce",
       "environment": "production",
       "version": "1.2.0",
       "status": "SUCCESS"
     }'
   ```

#### Schema Version Conflicts

**Issue**: Schema version conflict between environments
**Resolution**:

1. Identify the conflict:
   ```bash
   # Compare schema versions between environments
   curl -X GET "http://localhost:8080/api/v1/migrations/compare?domain=social-commerce&source_env=staging&target_env=production" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

2. Analyze the differences and develop a resolution plan:
   ```bash
   # Check specific differences
   ./mvnw verify -Pmigration-diff -Dmigration.domain=social-commerce -Dmigration.source=staging -Dmigration.target=production
   ```

3. Create a reconciliation migration:
   ```bash
   # Generate reconciliation migration
   ./scripts/generate-reconciliation.sh social-commerce staging production > \
     src/main/resources/db/migration/postgresql/social-commerce/V1_2_1__reconcile_environments.sql
   ```

4. Execute the reconciliation migration:
   ```bash
   ./mvnw verify -Pmigration-execute -Dmigration.environment=production -Dmigration.domain=social-commerce
   ```

#### Database Connection Issues

**Issue**: Unable to connect to database
**Resolution**:

1. Check connection parameters:
   ```bash
   # Verify configuration
   cat config/application.yml | grep -A 10 "datasource"
   ```

2. Verify network connectivity:
   ```bash
   # Check network connectivity
   ping ${POSTGRES_HOST}
   nc -zv ${POSTGRES_HOST} ${POSTGRES_PORT}
   ```

3. Check for connection pool exhaustion:
   ```bash
   # Get connection pool metrics
   curl -X GET "http://localhost:8080/actuator/metrics/hikari.connections" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

4. Adjust connection pool settings if needed:
   ```yaml
   # Hikari connection pool configuration
   spring:
     datasource:
       hikari:
         maximum-pool-size: 20
         minimum-idle: 5
         connection-timeout: 30000
         idle-timeout: 600000
   ```

#### Performance Degradation

**Issue**: Slow migration execution
**Resolution**:

1. Identify slow migrations:
   ```bash
   # Get performance metrics
   curl -X GET "http://localhost:8080/actuator/metrics/migration.execution?tag=domain:social-commerce" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

2. Check database performance:
   ```sql
   -- PostgreSQL: Check for long-running queries
   SELECT pid, now() - query_start AS duration, query
   FROM pg_stat_activity
   WHERE state = 'active' AND now() - query_start > interval '5 minutes'
   ORDER BY duration DESC;
   ```

3. Optimize migration scripts:
   - Add proper indexes before large data operations
   - Use batching for large data migrations
   - Consider partitioning large tables
   - Use background jobs for non-critical updates

4. Adjust execution windows for large migrations:
   ```bash
   # Schedule migration during off-peak hours
   gh workflow run database-migration.yml \
     -F environment=production \
     -F domain=social-commerce \
     -F version=1.3.0 \
     -F scheduled=true \
     -F schedule-time="2023-06-25T02:00:00Z"
   ```

### Diagnostic Procedures

#### Database Health Checks

Perform comprehensive database health checks:

```bash
# PostgreSQL health check
./scripts/postgres-health-check.sh ${POSTGRES_HOST} ${POSTGRES_PORT} ${POSTGRES_USER} ${POSTGRES_PASSWORD} ${POSTGRES_DB}

# MongoDB health check
./scripts/mongo-health-check.sh ${MONGODB_HOST} ${MONGODB_PORT} ${MONGODB_USER} ${MONGODB_PASSWORD}

# Redis health check
./scripts/redis-health-check.sh ${REDIS_HOST} ${REDIS_PORT} ${REDIS_PASSWORD}

# Elasticsearch health check
./scripts/elasticsearch-health-check.sh ${ELASTICSEARCH_HOST} ${ELASTICSEARCH_PORT}
```

#### Service Diagnostics

Run diagnostic checks on the migration service:

```bash
# Check service threads
curl -X GET "http://localhost:8080/actuator/threaddump" \
  -H "Authorization: Bearer ${TOKEN}" > thread-dump.txt

# Check JVM memory usage
curl -X GET "http://localhost:8080/actuator/metrics/jvm.memory.used" \
  -H "Authorization: Bearer ${TOKEN}"

# Check environment configuration
curl -X GET "http://localhost:8080/actuator/env" \
  -H "Authorization: Bearer ${TOKEN}" > environment-config.json

# Check service dependencies
curl -X GET "http://localhost:8080/actuator/health/dependencies" \
  -H "Authorization: Bearer ${TOKEN}"
```

#### Migration Validation

Validate migrations without executing them:

```bash
# Validate specific migration
./mvnw verify -Pmigration-validate \
  -Dmigration.environment=production \
  -Dmigration.domain=social-commerce \
  -Dmigration.version=1.3.0 \
  -Dmigration.dryRun=true

# Validate migration on specific database
./mvnw verify -Pmigration-validate \
  -Dmigration.environment=production \
  -Dmigration.domain=social-commerce \
  -Dmigration.version=1.3.0 \
  -Dmigration.dryRun=true \
  -Dmigration.database=${TEST_DATABASE_URL}
```

### Recovery Procedures

#### Failed Migration Recovery

Recover from a failed migration:

1. **Analyze the failure**:
   ```bash
   # Check logs for error details
   cat logs/migrations.log | grep "Migration V1_3_0"
   ```

2. **Determine recovery strategy**:
   - Fix and retry
   - Skip and mark as completed
   - Rollback to previous version

3. **Fix and retry approach**:
   ```bash
   # Fix the migration script
   vi src/main/resources/db/migration/postgresql/social-commerce/V1_3_0__add_product_variants.sql
   
   # Repair the migration registry
   curl -X POST "http://localhost:8080/api/v1/migrations/repair" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "domain": "social-commerce",
       "environment": "production",
       "version": "1.3.0",
       "status": "FAILED"
     }'
   
   # Retry the migration
   ./mvnw verify -Pmigration-execute \
     -Dmigration.environment=production \
     -Dmigration.domain=social-commerce \
     -Dmigration.version=1.3.0
   ```

4. **Skip and mark as completed approach**:
   ```bash
   # Mark migration as completed without executing
   curl -X POST "http://localhost:8080/api/v1/migrations/repair" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "domain": "social-commerce",
       "environment": "production",
       "version": "1.3.0",
       "status": "SUCCESS"
     }'
   ```

5. **Rollback approach**:
   ```bash
   # Execute rollback script
   curl -X POST "http://localhost:8080/api/v1/migrations/rollback" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "domain": "social-commerce",
       "environment": "production",
       "version": "1.3.0",
       "rollbackScript": "ALTER TABLE social_commerce.products DROP COLUMN IF EXISTS has_variants; DROP TABLE IF EXISTS social_commerce.product_variants;"
     }'
   ```

#### Database Restore

Restore database from backup if necessary:

```bash
# PostgreSQL restore
pg_restore -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c backup/social_commerce_20230615.dump

# MongoDB restore
mongorestore --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} --authenticationDatabase admin --db warehousing backup/mongodb_20230615/warehousing

# Redis restore
cat backup/redis_20230615.aof | redis-cli -h ${REDIS_HOST} -p ${REDIS_PORT} -a ${REDIS_PASSWORD} --pipe

# Elasticsearch restore
curl -X POST "http://${ELASTICSEARCH_HOST}:${ELASTICSEARCH_PORT}/_snapshot/backup_repo/snapshot_20230615/_restore" \
  -H "Content-Type: application/json" \
  -d '{"indices": "analytics-*"}'
```

#### Emergency Rollback

Perform emergency rollback to previous version:

```bash
# Full schema rollback for critical issues
./scripts/emergency-rollback.sh \
  --domain social-commerce \
  --environment production \
  --target-version 1.2.0 \
  --backup-file backup/social_commerce_20230615.dump
```

## Routine Maintenance

### Schema Optimization

Regularly optimize database schemas:

1. **Identify optimization opportunities**:
   ```bash
   # PostgreSQL: Identify unused indexes
   psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
   SELECT
     schemaname || '.' || relname as table,
     indexrelname as index,
     pg_size_pretty(pg_relation_size(i.indexrelid)) as index_size,
     idx_scan as index_scans
   FROM pg_stat_user_indexes ui
   JOIN pg_index i ON ui.indexrelid = i.indexrelid
   WHERE idx_scan = 0 AND indisunique IS FALSE
   ORDER BY pg_relation_size(i.indexrelid) DESC;"
   ```

2. **Create optimization migration**:
   ```bash
   # Create optimization migration script
   cat > src/main/resources/db/migration/postgresql/social-commerce/V1_3_1__schema_optimization.sql << EOF
   -- Optimization: Remove unused indexes and add better ones
   
   -- Drop unused indexes
   DROP INDEX IF EXISTS social_commerce.idx_products_description;
   
   -- Add optimized indexes
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_category_price ON social_commerce.products (category_id, price);
   
   -- Update statistics
   ANALYZE social_commerce.products;
   EOF
   ```

3. **Execute optimization during low-traffic periods**:
   ```bash
   ./mvnw verify -Pmigration-execute \
     -Dmigration.environment=production \
     -Dmigration.domain=social-commerce \
     -Dmigration.version=1.3.1 \
     -Dmigration.lowImpact=true
   ```

### Audit and Compliance

Maintain audit records for compliance:

1. **Generate migration audit report**:
   ```bash
   # Export migration history
   curl -X GET "http://localhost:8080/api/v1/migrations/history?domain=all&environment=production&format=csv" \
     -H "Authorization: Bearer ${TOKEN}" > migration_audit_$(date +%Y%m%d).csv
   ```

2. **Verify compliance with standards**:
   ```bash
   # Run compliance check
   ./scripts/check-compliance.sh \
     --standard pci-dss \
     --domain social-commerce \
     --report-file compliance_report_$(date +%Y%m%d).pdf
   ```

3. **Archive audit logs**:
   ```bash
   # Archive logs older than 90 days
   find logs -name "migrations*.log" -type f -mtime +90 -exec gzip {} \;
   
   # Move archived logs to long-term storage
   aws s3 cp logs/archive/ s3://gogidix-ecommerce-audit-logs/database-migrations/ --recursive
   ```

### Backup Management

Manage database backups:

1. **Schedule regular backups**:
   ```bash
   # Create backup schedule
   cat > scripts/backup-schedule.sh << EOF
   #!/bin/bash
   
   # PostgreSQL backup
   pg_dump -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d social_commerce -F c -f backup/social_commerce_\$(date +%Y%m%d).dump
   pg_dump -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d warehousing -F c -f backup/warehousing_\$(date +%Y%m%d).dump
   pg_dump -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d courier_services -F c -f backup/courier_services_\$(date +%Y%m%d).dump
   pg_dump -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d centralized_dashboard -F c -f backup/centralized_dashboard_\$(date +%Y%m%d).dump
   
   # MongoDB backup
   mongodump --host \${MONGODB_HOST} --port \${MONGODB_PORT} --username \${MONGODB_USER} --password \${MONGODB_PASSWORD} --authenticationDatabase admin --db warehousing --out backup/mongodb_\$(date +%Y%m%d)
   
   # Redis backup
   redis-cli -h \${REDIS_HOST} -p \${REDIS_PORT} -a \${REDIS_PASSWORD} --rdb backup/redis_\$(date +%Y%m%d).rdb
   
   # Elasticsearch backup
   curl -X PUT "http://\${ELASTICSEARCH_HOST}:\${ELASTICSEARCH_PORT}/_snapshot/backup_repo/snapshot_\$(date +%Y%m%d)"
   
   # Archive backups older than 30 days
   find backup -type f -name "*.dump" -mtime +30 -exec gzip {} \;
   find backup -type f -name "*.rdb" -mtime +30 -exec gzip {} \;
   
   # Move archived backups to long-term storage
   aws s3 cp backup/ s3://gogidix-ecommerce-database-backups/ --recursive --exclude "*" --include "*.gz"
   EOF
   
   # Make script executable
   chmod +x scripts/backup-schedule.sh
   
   # Add to crontab
   (crontab -l 2>/dev/null; echo "0 2 * * * /path/to/scripts/backup-schedule.sh") | crontab -
   ```

2. **Verify backup integrity**:
   ```bash
   # Verify PostgreSQL backup
   pg_restore -l backup/social_commerce_$(date +%Y%m%d).dump > /dev/null
   
   # Verify MongoDB backup
   mongorestore --host ${MONGODB_HOST} --port ${MONGODB_PORT} --username ${MONGODB_USER} --password ${MONGODB_PASSWORD} --authenticationDatabase admin --db warehousing_test --drop --dryRun backup/mongodb_$(date +%Y%m%d)/warehousing
   ```

3. **Test restore procedures**:
   ```bash
   # Schedule monthly restore test
   cat > scripts/test-restore.sh << EOF
   #!/bin/bash
   
   # Create test databases
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -c "CREATE DATABASE social_commerce_test WITH TEMPLATE template0;"
   
   # Restore from backup to test database
   pg_restore -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d social_commerce_test backup/social_commerce_\$(date +%Y%m%d).dump
   
   # Verify restore
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d social_commerce_test -c "SELECT count(*) FROM products;"
   
   # Clean up test database
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -c "DROP DATABASE social_commerce_test;"
   EOF
   
   # Make script executable
   chmod +x scripts/test-restore.sh
   
   # Add to crontab (first day of each month)
   (crontab -l 2>/dev/null; echo "0 3 1 * * /path/to/scripts/test-restore.sh") | crontab -
   ```

## Database Version Control

### Migration Lifecycle Management

Manage the migration lifecycle:

1. **Planning phase**:
   - Document schema changes in advance
   - Review migration scripts for standards compliance
   - Assess performance impact
   - Identify dependencies

2. **Development phase**:
   - Create migration scripts
   - Test in development environment
   - Document in migration registry

3. **Review phase**:
   - Peer review of migration scripts
   - Performance review
   - Security review
   - Compliance check

4. **Testing phase**:
   - Execute in testing environment
   - Verify application compatibility
   - Measure performance impact
   - Test rollback procedures

5. **Staging phase**:
   - Execute in staging environment
   - Full integration testing
   - Performance validation
   - Final approval

6. **Production phase**:
   - Schedule maintenance window
   - Execute in production environment
   - Verify successful execution
   - Monitor for issues

7. **Post-deployment phase**:
   - Document final status
   - Update documentation
   - Archive migration artifacts
   - Conduct post-mortem if issues occurred

### Version Dependency Management

Manage dependencies between migrations:

1. **Define dependencies in documentation**:
   ```markdown
   # V1_3_0__add_product_variants.sql
   
   ## Dependencies
   - Requires V1_2_0__add_product_categories.sql
   - Must be executed before V1_4_0__add_variant_pricing.sql
   ```

2. **Enforce dependency order in migration registry**:
   ```bash
   # Update migration registry with dependencies
   curl -X POST "http://localhost:8080/api/v1/migrations/dependencies" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "domain": "social-commerce",
       "version": "1.3.0",
       "requires": ["1.2.0"],
       "requiredBy": ["1.4.0"]
     }'
   ```

3. **Validate dependencies before execution**:
   ```bash
   # Validate migration dependencies
   ./mvnw verify -Pmigration-validate \
     -Dmigration.environment=production \
     -Dmigration.domain=social-commerce \
     -Dmigration.version=1.3.0 \
     -Dmigration.validateDependencies=true
   ```

### Cross-Domain Migration Coordination

Coordinate migrations across domains:

1. **Define cross-domain dependencies**:
   ```bash
   # Create cross-domain dependency configuration
   cat > config/cross-domain-dependencies.json << EOF
   {
     "social-commerce": {
       "1.5.0": {
         "requires": {
           "warehousing": "1.3.0"
         }
       }
     },
     "warehousing": {
       "1.4.0": {
         "requires": {
           "courier-services": "1.2.0"
         }
       }
     }
   }
   EOF
   ```

2. **Validate cross-domain dependencies**:
   ```bash
   # Validate cross-domain dependencies
   ./scripts/validate-cross-domain.sh \
     --source-domain social-commerce \
     --source-version 1.5.0 \
     --environment production
   ```

3. **Execute coordinated migrations**:
   ```bash
   # Execute multi-domain migration
   ./scripts/execute-coordinated-migration.sh \
     --domains "warehousing,social-commerce" \
     --versions "1.3.0,1.5.0" \
     --environment production
   ```

## Multi-Environment Management

### Environment Promotion

Promote migrations between environments:

1. **Validate migration in source environment**:
   ```bash
   # Validate migration in staging
   ./mvnw verify -Pmigration-validate \
     -Dmigration.environment=staging \
     -Dmigration.domain=social-commerce
   ```

2. **Export migration status from source environment**:
   ```bash
   # Export migration status from staging
   curl -X GET "http://localhost:8080/api/v1/migrations/status?domain=social-commerce&environment=staging" \
     -H "Authorization: Bearer ${TOKEN}" > staging-status.json
   ```

3. **Compare with target environment**:
   ```bash
   # Compare with production environment
   curl -X GET "http://localhost:8080/api/v1/migrations/compare?domain=social-commerce&source_env=staging&target_env=production" \
     -H "Authorization: Bearer ${TOKEN}" > environment-diff.json
   ```

4. **Promote migrations to target environment**:
   ```bash
   # Promote migrations to production
   ./scripts/promote-migrations.sh \
     --source staging \
     --target production \
     --domain social-commerce \
     --status-file staging-status.json
   ```

### Environment Configuration Management

Manage environment-specific configurations:

1. **Define environment-specific settings**:
   ```yaml
   # Development environment settings
   development:
     autoExecute: true
     validateOnStartup: true
     allowSchemaReset: true
     connectionPool:
       maxSize: 10
       timeout: 30000
   
   # Production environment settings
   production:
     autoExecute: false
     validateOnStartup: true
     allowSchemaReset: false
     requireApproval: true
     approvers: ["admin", "dba"]
     connectionPool:
       maxSize: 30
       timeout: 60000
   ```

2. **Apply environment-specific settings**:
   ```bash
   # Update environment configuration
   curl -X PUT "http://localhost:8080/api/v1/config/environment/production" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "autoExecute": false,
       "validateOnStartup": true,
       "allowSchemaReset": false,
       "requireApproval": true,
       "approvers": ["admin", "dba"],
       "connectionPool": {
         "maxSize": 30,
         "timeout": 60000
       }
     }'
   ```

3. **Verify environment configuration**:
   ```bash
   # Get environment configuration
   curl -X GET "http://localhost:8080/api/v1/config/environment/production" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

## Multi-Region Management

### Region-Specific Migrations

Manage region-specific migrations:

1. **Create region-specific migration directory**:
   ```bash
   # Create region directories
   mkdir -p src/main/resources/db/migration/postgresql/social-commerce/regions/{europe,africa}
   ```

2. **Create region-specific migration scripts**:
   ```bash
   # Create European region script
   cat > src/main/resources/db/migration/postgresql/social-commerce/regions/europe/V1_0_0__gdpr_compliance.sql << EOF
   -- European region GDPR compliance changes
   
   -- Add GDPR-specific columns
   ALTER TABLE social_commerce.users ADD COLUMN consent_timestamp TIMESTAMP WITH TIME ZONE;
   ALTER TABLE social_commerce.users ADD COLUMN data_retention_policy VARCHAR(50) DEFAULT 'standard';
   ALTER TABLE social_commerce.users ADD COLUMN marketing_consent BOOLEAN DEFAULT FALSE;
   
   -- Create data export function
   CREATE OR REPLACE FUNCTION social_commerce.export_user_data(user_id INTEGER)
   RETURNS JSON AS $$
   DECLARE
     user_data JSON;
   BEGIN
     SELECT row_to_json(u) INTO user_data
     FROM (
       SELECT * FROM social_commerce.users WHERE id = user_id
     ) u;
     
     RETURN user_data;
   END;
   $$ LANGUAGE plpgsql;
   EOF
   
   # Create African region script
   cat > src/main/resources/db/migration/postgresql/social-commerce/regions/africa/V1_0_0__popia_compliance.sql << EOF
   -- African region POPIA compliance changes
   
   -- Add POPIA-specific columns
   ALTER TABLE social_commerce.users ADD COLUMN popia_consent_timestamp TIMESTAMP WITH TIME ZONE;
   ALTER TABLE social_commerce.users ADD COLUMN information_officer VARCHAR(100);
   ALTER TABLE social_commerce.users ADD COLUMN processing_purpose VARCHAR(255);
   
   -- Create compliance function
   CREATE OR REPLACE FUNCTION social_commerce.verify_popia_compliance()
   RETURNS TRIGGER AS $$
   BEGIN
     IF NEW.popia_consent_timestamp IS NULL THEN
       RAISE EXCEPTION 'POPIA consent timestamp is required';
     END IF;
     
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;
   
   -- Create trigger
   CREATE TRIGGER enforce_popia_compliance
   BEFORE INSERT OR UPDATE ON social_commerce.users
   FOR EACH ROW
   EXECUTE FUNCTION social_commerce.verify_popia_compliance();
   EOF
   ```

3. **Configure region-specific execution**:
   ```bash
   # Update region configuration
   cat > config/regions.yml << EOF
   regions:
     europe:
       countries: [AT, BE, BG, HR, CY, CZ, DK, EE, FI, FR, DE, GR, HU, IE, IT, LV, LT, LU, MT, NL, PL, PT, RO, SK, SI, ES, SE]
       databases:
         postgresql: jdbc:postgresql://eu-postgres.gogidix-ecommerce.com:5432/social_commerce
         mongodb: mongodb://eu-mongodb.gogidix-ecommerce.com:27017/warehousing
       migrations:
         locations:
           - classpath:db/migration/{technology}/{domain}
           - classpath:db/migration/{technology}/{domain}/regions/europe
     
     africa:
       countries: [ZA, NG, KE, GH, ET, TZ, UG, RW, ZM, ZW]
       databases:
         postgresql: jdbc:postgresql://af-postgres.gogidix-ecommerce.com:5432/social_commerce
         mongodb: mongodb://af-mongodb.gogidix-ecommerce.com:27017/warehousing
       migrations:
         locations:
           - classpath:db/migration/{technology}/{domain}
           - classpath:db/migration/{technology}/{domain}/regions/africa
   EOF
   ```

4. **Execute region-specific migrations**:
   ```bash
   # Execute European region migrations
   ./mvnw verify -Pmigration-execute \
     -Dmigration.environment=production \
     -Dmigration.domain=social-commerce \
     -Dmigration.region=europe
   
   # Execute African region migrations
   ./mvnw verify -Pmigration-execute \
     -Dmigration.environment=production \
     -Dmigration.domain=social-commerce \
     -Dmigration.region=africa
   ```

### Cross-Region Coordination

Coordinate migrations across regions:

1. **Define migration sequence**:
   ```bash
   # Create region sequence configuration
   cat > config/region-sequence.yml << EOF
   sequence:
     - global
     - europe
     - africa
   
   dependencies:
     europe:
       requires: [global]
     africa:
       requires: [global]
   EOF
   ```

2. **Execute sequenced migration**:
   ```bash
   # Execute sequenced migration across regions
   ./scripts/region-sequence-migration.sh \
     --domain social-commerce \
     --environment production \
     --version 1.5.0
   ```

3. **Monitor cross-region status**:
   ```bash
   # Get cross-region migration status
   curl -X GET "http://localhost:8080/api/v1/migrations/status?domain=social-commerce&environment=production&groupBy=region" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

## Performance Optimization

### Migration Performance Tuning

Optimize migration performance:

1. **Analyze migration performance**:
   ```bash
   # Get migration performance metrics
   curl -X GET "http://localhost:8080/actuator/metrics/migration.execution?tag=domain:social-commerce&tag=environment:production" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

2. **Identify slow migrations**:
   ```bash
   # Query migration registry for slow migrations
   psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
   SELECT domain, version, description, execution_time_ms, executed_at
   FROM migration_history
   WHERE execution_time_ms > 5000
   ORDER BY execution_time_ms DESC
   LIMIT 10;"
   ```

3. **Optimize migration scripts**:
   ```sql
   -- Before optimization
   ALTER TABLE products ADD COLUMN search_vector tsvector;
   UPDATE products SET search_vector = to_tsvector('english', name || ' ' || description);
   CREATE INDEX idx_products_search_vector ON products USING gin(search_vector);
   
   -- After optimization
   ALTER TABLE products ADD COLUMN search_vector tsvector;
   CREATE INDEX idx_products_search_vector ON products USING gin(search_vector);
   
   -- Use batch processing for large tables
   DO $$
   DECLARE
     batch_size INTEGER := 10000;
     max_id INTEGER;
     current_id INTEGER := 0;
   BEGIN
     SELECT MAX(id) INTO max_id FROM products;
     
     WHILE current_id < max_id LOOP
       UPDATE products
       SET search_vector = to_tsvector('english', name || ' ' || description)
       WHERE id > current_id AND id <= current_id + batch_size;
       
       current_id := current_id + batch_size;
       COMMIT;
     END LOOP;
   END $$;
   ```

4. **Configure parallel migration execution**:
   ```yaml
   # Configure parallel execution
   migration:
     executor:
       corePoolSize: 5
       maxPoolSize: 10
       queueCapacity: 25
       parallelExecutionEnabled: true
       independentScriptsOnly: true
   ```

### Database Index Optimization

Optimize database indexes:

1. **Analyze index usage**:
   ```sql
   -- PostgreSQL: Check index usage
   SELECT
     schemaname || '.' || relname as table,
     indexrelname as index,
     pg_size_pretty(pg_relation_size(i.indexrelid)) as index_size,
     idx_scan as index_scans,
     idx_tup_read as tuples_read,
     idx_tup_fetch as tuples_fetched
   FROM pg_stat_user_indexes ui
   JOIN pg_index i ON ui.indexrelid = i.indexrelid
   ORDER BY pg_relation_size(i.indexrelid) DESC
   LIMIT 20;
   ```

2. **Create index optimization migration**:
   ```bash
   # Create index optimization migration script
   cat > src/main/resources/db/migration/postgresql/social-commerce/V1_3_2__index_optimization.sql << EOF
   -- Index optimization migration
   
   -- Drop unused indexes
   DROP INDEX IF EXISTS social_commerce.idx_products_created_at;
   
   -- Replace with more efficient indexes
   DROP INDEX IF EXISTS social_commerce.idx_products_name;
   CREATE INDEX CONCURRENTLY idx_products_name_category ON social_commerce.products (name, category_id);
   
   -- Add missing indexes for foreign keys
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_order_items_product_id ON social_commerce.order_items (product_id);
   
   -- Add functional indexes
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_products_name_lower ON social_commerce.products (lower(name));
   
   -- Update statistics
   ANALYZE social_commerce.products;
   ANALYZE social_commerce.order_items;
   EOF
   ```

3. **Execute optimization during maintenance window**:
   ```bash
   # Schedule index optimization
   gh workflow run database-migration.yml \
     -F environment=production \
     -F domain=social-commerce \
     -F version=1.3.2 \
     -F scheduled=true \
     -F schedule-time="2023-06-25T02:00:00Z" \
     -F low-impact=true
   ```

### Connection Pool Optimization

Optimize database connection pool:

1. **Analyze connection usage**:
   ```bash
   # Get connection pool metrics
   curl -X GET "http://localhost:8080/actuator/metrics/hikari.connections.active" \
     -H "Authorization: Bearer ${TOKEN}"
   
   curl -X GET "http://localhost:8080/actuator/metrics/hikari.connections.max" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

2. **Configure connection pool settings**:
   ```yaml
   # Optimize connection pool settings
   spring:
     datasource:
       hikari:
         maximum-pool-size: 20
         minimum-idle: 5
         idle-timeout: 300000
         max-lifetime: 1800000
         connection-timeout: 30000
         leak-detection-threshold: 60000
   ```

3. **Implement connection pool monitoring**:
   ```bash
   # Create connection pool monitoring script
   cat > scripts/monitor-connection-pool.sh << EOF
   #!/bin/bash
   
   # Get connection pool metrics
   active=\$(curl -s -X GET "http://localhost:8080/actuator/metrics/hikari.connections.active" \
     -H "Authorization: Bearer \${TOKEN}" | jq -r '.measurements[0].value')
   
   max=\$(curl -s -X GET "http://localhost:8080/actuator/metrics/hikari.connections.max" \
     -H "Authorization: Bearer \${TOKEN}" | jq -r '.measurements[0].value')
   
   usage=\$(echo "scale=2; \$active / \$max * 100" | bc)
   
   echo "Connection pool usage: \$usage% (\$active/\$max)"
   
   # Alert if usage is high
   if (( \$(echo "\$usage > 80" | bc -l) )); then
     echo "WARNING: High connection pool usage"
     
     # Send alert
     curl -X POST "https://alert-service.gogidix-ecommerce.com/api/alerts" \
       -H "Content-Type: application/json" \
       -d "{\"service\": \"database-migrations\", \"level\": \"warning\", \"message\": \"High connection pool usage: \$usage%\"}"
   fi
   EOF
   
   # Make script executable
   chmod +x scripts/monitor-connection-pool.sh
   
   # Add to crontab
   (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/scripts/monitor-connection-pool.sh") | crontab -
   ```

## Security Management

### Access Control Management

Manage access to migration operations:

1. **Define role-based access control**:
   ```yaml
   # Configure RBAC
   security:
     rbac:
       roles:
         ADMIN:
           permissions:
             - "migrations:execute:*"
             - "migrations:validate:*"
             - "migrations:rollback:*"
             - "migrations:repair:*"
             - "migrations:view:*"
         DBA:
           permissions:
             - "migrations:execute:*"
             - "migrations:validate:*"
             - "migrations:rollback:*"
             - "migrations:repair:*"
             - "migrations:view:*"
         DEVELOPER:
           permissions:
             - "migrations:execute:development"
             - "migrations:execute:testing"
             - "migrations:validate:*"
             - "migrations:view:*"
         DEVOPS:
           permissions:
             - "migrations:execute:development"
             - "migrations:execute:testing"
             - "migrations:execute:staging"
             - "migrations:validate:*"
             - "migrations:view:*"
         AUDITOR:
           permissions:
             - "migrations:view:*"
   ```

2. **Assign roles to users**:
   ```bash
   # Assign roles to users
   curl -X POST "http://localhost:8080/api/v1/users/roles" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${TOKEN}" \
     -d '{
       "username": "john.smith",
       "roles": ["DEVELOPER", "DEVOPS"]
     }'
   ```

3. **Verify access control**:
   ```bash
   # Check user permissions
   curl -X GET "http://localhost:8080/api/v1/users/john.smith/permissions" \
     -H "Authorization: Bearer ${TOKEN}"
   ```

### Credential Management

Securely manage database credentials:

1. **Integrate with secret management service**:
   ```yaml
   # Configure secrets integration
   secrets:
     provider: vault
     vault:
       uri: https://vault.gogidix-ecommerce.com
       authentication:
         method: kubernetes
         role: database-migrations
       paths:
         postgresql: secret/database/postgresql
         mongodb: secret/database/mongodb
         redis: secret/database/redis
         elasticsearch: secret/database/elasticsearch
   ```

2. **Rotate credentials regularly**:
   ```bash
   # Create credential rotation script
   cat > scripts/rotate-credentials.sh << EOF
   #!/bin/bash
   
   # Generate new password
   new_password=\$(openssl rand -base64 32)
   
   # Update in database
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_ADMIN_USER} -d \${POSTGRES_DB} -c "
   ALTER USER migration_user WITH PASSWORD '\${new_password}';"
   
   # Update in vault
   vault kv put secret/database/postgresql/migration_user password=\${new_password}
   
   # Restart service to pick up new credentials
   kubectl rollout restart deployment database-migrations -n central-configuration
   EOF
   
   # Make script executable
   chmod +x scripts/rotate-credentials.sh
   
   # Schedule quarterly rotation
   (crontab -l 2>/dev/null; echo "0 0 1 */3 * /path/to/scripts/rotate-credentials.sh") | crontab -
   ```

3. **Audit credential access**:
   ```bash
   # Audit credential access logs
   vault audit list
   
   # Enable detailed audit if not already enabled
   vault audit enable file file_path=/var/log/vault_audit.log
   
   # Review credential access
   cat /var/log/vault_audit.log | grep "secret/database/postgresql" | jq
   ```

### Audit Logging

Maintain comprehensive audit logs:

1. **Configure detailed audit logging**:
   ```yaml
   # Configure audit logging
   audit:
     enabled: true
     include:
       - migration:execute
       - migration:validate
       - migration:rollback
       - migration:repair
       - config:update
       - user:login
     fields:
       - timestamp
       - username
       - action
       - domain
       - environment
       - version
       - result
       - source_ip
     storage:
       type: database
       retention_days: 365
   ```

2. **Generate audit reports**:
   ```bash
   # Generate monthly audit report
   cat > scripts/generate-audit-report.sh << EOF
   #!/bin/bash
   
   # Set date range for last month
   start_date=\$(date -d "last month" +%Y-%m-01)
   end_date=\$(date -d "\$start_date +1 month" +%Y-%m-%d)
   
   # Query audit logs
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d migration_registry -c "
   COPY (
     SELECT timestamp, username, action, domain, environment, version, result, source_ip
     FROM audit_log
     WHERE timestamp >= '\${start_date}' AND timestamp < '\${end_date}'
     ORDER BY timestamp
   ) TO STDOUT WITH CSV HEADER" > audit_report_\$(date -d "last month" +%Y-%m).csv
   
   # Generate summary statistics
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d migration_registry -c "
   COPY (
     SELECT action, count(*) as count, count(distinct username) as distinct_users
     FROM audit_log
     WHERE timestamp >= '\${start_date}' AND timestamp < '\${end_date}'
     GROUP BY action
     ORDER BY count DESC
   ) TO STDOUT WITH CSV HEADER" > audit_summary_\$(date -d "last month" +%Y-%m).csv
   
   # Send report to compliance team
   mail -s "Database Migration Audit Report \$(date -d "last month" +%Y-%m)" \
     -a audit_report_\$(date -d "last month" +%Y-%m).csv \
     -a audit_summary_\$(date -d "last month" +%Y-%m).csv \
     compliance@gogidix-ecommerce.com < /dev/null
   EOF
   
   # Make script executable
   chmod +x scripts/generate-audit-report.sh
   
   # Schedule monthly report generation
   (crontab -l 2>/dev/null; echo "0 6 1 * * /path/to/scripts/generate-audit-report.sh") | crontab -
   ```

3. **Implement audit log analysis**:
   ```bash
   # Create audit analysis script
   cat > scripts/analyze-audit-logs.sh << EOF
   #!/bin/bash
   
   # Detect unusual patterns
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d migration_registry -c "
   SELECT username, action, count(*), min(timestamp), max(timestamp)
   FROM audit_log
   WHERE timestamp >= NOW() - INTERVAL '24 hours'
   GROUP BY username, action
   HAVING count(*) > 20
   ORDER BY count(*) DESC;"
   
   # Detect failed operations
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d migration_registry -c "
   SELECT username, action, domain, environment, version, timestamp, source_ip
   FROM audit_log
   WHERE result = 'FAILURE'
   AND timestamp >= NOW() - INTERVAL '24 hours'
   ORDER BY timestamp DESC;"
   
   # Detect operations outside business hours
   psql -h \${POSTGRES_HOST} -U \${POSTGRES_USER} -d migration_registry -c "
   SELECT username, action, domain, environment, version, timestamp, source_ip
   FROM audit_log
   WHERE action = 'migration:execute'
   AND environment = 'production'
   AND EXTRACT(HOUR FROM timestamp) NOT BETWEEN 1 AND 5
   AND timestamp >= NOW() - INTERVAL '24 hours'
   ORDER BY timestamp DESC;"
   EOF
   
   # Make script executable
   chmod +x scripts/analyze-audit-logs.sh
   
   # Schedule daily analysis
   (crontab -l 2>/dev/null; echo "30 8 * * * /path/to/scripts/analyze-audit-logs.sh") | crontab -
   ```

## Advanced Monitoring and Observability

### Enterprise Monitoring Stack

Deploy comprehensive monitoring for production environments:

```yaml
# Prometheus Configuration
monitoring:
  prometheus:
    enabled: true
    endpoint: /actuator/prometheus
    scrape-interval: 15s
    metrics:
      custom:
        - migration.execution.time
        - migration.success.rate
        - migration.failure.count
        - database.connection.pool.utilization
        - schema.validation.duration
        
  # Grafana Dashboards
  grafana:
    dashboards:
      - migration-overview
      - database-performance
      - security-audit
      - compliance-metrics
      
  # Alerting Rules
  alerts:
    critical:
      - migration-failure
      - database-connection-loss
      - security-breach-detection
    warning:
      - high-execution-time
      - connection-pool-exhaustion
      - schema-drift-detection
```

### Real-time Performance Monitoring

```bash
# Advanced Performance Monitoring Script
cat > scripts/advanced-monitoring.sh << 'EOF'
#!/bin/bash

# Real-time migration performance monitoring
monitor_migration_performance() {
    echo "=== Migration Performance Metrics ==="
    
    # Get current execution metrics
    curl -s "http://localhost:8080/actuator/metrics/migration.execution" | \
        jq -r '.measurements[] | select(.statistic=="TOTAL_TIME") | .value'
    
    # Monitor database connection pool
    curl -s "http://localhost:8080/actuator/metrics/hikari.connections.active" | \
        jq -r '.measurements[0].value'
    
    # Check memory usage
    curl -s "http://localhost:8080/actuator/metrics/jvm.memory.used" | \
        jq -r '.measurements[] | select(.statistic=="VALUE") | .value'
    
    # Monitor schema validation time
    curl -s "http://localhost:8080/actuator/metrics/schema.validation.duration" | \
        jq -r '.measurements[] | select(.statistic=="MEAN") | .value'
}

# Continuous monitoring loop
while true; do
    monitor_migration_performance
    sleep 30
done
EOF
```

### Distributed Tracing Setup

Configure distributed tracing for microservices:

```yaml
# Jaeger Tracing Configuration
tracing:
  jaeger:
    enabled: true
    service-name: database-migrations
    sampler:
      type: probabilistic
      param: 1.0
    reporter:
      log-spans: true
      sender:
        agent-host: jaeger-agent
        agent-port: 6831
        
# Custom Spans
custom-spans:
  - name: "migration-execution"
    tags:
      - domain
      - environment
      - version
  - name: "schema-validation"
    tags:
      - technology
      - validation-type
  - name: "rollback-operation"
    tags:
      - rollback-reason
      - affected-tables
```

### Automated Alerting System

```yaml
# Advanced Alerting Configuration
alerting:
  channels:
    slack:
      webhook: ${SLACK_WEBHOOK_URL}
      channel: "#database-alerts"
    email:
      smtp-server: mail.gogidix-ecommerce.com
      recipients:
        - dba-team@gogidix-ecommerce.com
        - devops-team@gogidix-ecommerce.com
    pagerduty:
      integration-key: ${PAGERDUTY_INTEGRATION_KEY}
      
  rules:
    critical:
      migration-failure:
        condition: "migration_failures_total > 0"
        duration: "0s"
        severity: "critical"
        message: "Database migration failed in {{ $labels.environment }}"
        
      database-unavailable:
        condition: "database_connectivity == 0"
        duration: "30s"
        severity: "critical"
        message: "Database connection lost for {{ $labels.database }}"
        
    warning:
      slow-migration:
        condition: "migration_execution_time > 300"
        duration: "60s"
        severity: "warning"
        message: "Migration taking longer than expected"
        
      high-memory-usage:
        condition: "jvm_memory_used_ratio > 0.8"
        duration: "120s"
        severity: "warning"
        message: "High memory usage detected"
```

## Enterprise Security Operations

### Advanced Security Monitoring

```bash
# Security Monitoring Dashboard
cat > scripts/security-monitor.sh << 'EOF'
#!/bin/bash

# Security event monitoring
monitor_security_events() {
    echo "=== Security Event Analysis ==="
    
    # Failed authentication attempts
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        date_trunc('hour', timestamp) as hour,
        count(*) as failed_attempts,
        array_agg(DISTINCT source_ip) as source_ips
    FROM audit_log 
    WHERE action = 'authentication' 
    AND result = 'FAILURE'
    AND timestamp >= NOW() - INTERVAL '24 hours'
    GROUP BY date_trunc('hour', timestamp)
    ORDER BY hour DESC;"
    
    # Unusual access patterns
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        username,
        count(*) as actions,
        array_agg(DISTINCT action) as action_types,
        array_agg(DISTINCT source_ip) as source_ips,
        min(timestamp) as first_action,
        max(timestamp) as last_action
    FROM audit_log
    WHERE timestamp >= NOW() - INTERVAL '1 hour'
    GROUP BY username
    HAVING count(*) > 50
    ORDER BY actions DESC;"
    
    # Check for privilege escalation attempts
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT *
    FROM audit_log
    WHERE action LIKE '%role%' OR action LIKE '%permission%'
    AND timestamp >= NOW() - INTERVAL '24 hours'
    ORDER BY timestamp DESC;"
}

# Run security monitoring
monitor_security_events
EOF
```

### Compliance Reporting

```bash
# Automated Compliance Reporting
cat > scripts/compliance-report.sh << 'EOF'
#!/bin/bash

# Generate GDPR compliance report
generate_gdpr_report() {
    echo "=== GDPR Compliance Report ==="
    
    # Data processing activities
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        domain,
        count(*) as migrations,
        count(CASE WHEN description LIKE '%personal%' OR description LIKE '%gdpr%' THEN 1 END) as data_processing_migrations,
        min(executed_at) as first_migration,
        max(executed_at) as latest_migration
    FROM migration_history
    WHERE environment = 'production'
    AND executed_at >= NOW() - INTERVAL '90 days'
    GROUP BY domain
    ORDER BY domain;"
    
    # Data retention compliance
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        'audit_logs' as data_type,
        count(*) as total_records,
        count(CASE WHEN timestamp < NOW() - INTERVAL '365 days' THEN 1 END) as records_past_retention,
        min(timestamp) as oldest_record,
        max(timestamp) as newest_record
    FROM audit_log;"
}

# Generate PCI DSS compliance report
generate_pci_report() {
    echo "=== PCI DSS Compliance Report ==="
    
    # Payment data related migrations
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        domain,
        version,
        description,
        executed_at,
        execution_time_ms
    FROM migration_history
    WHERE (description LIKE '%payment%' OR description LIKE '%card%' OR description LIKE '%transaction%')
    AND environment = 'production'
    AND executed_at >= NOW() - INTERVAL '90 days'
    ORDER BY executed_at DESC;"
    
    # Access control audit
    psql -h ${POSTGRES_HOST} -U ${POSTGRES_USER} -d migration_registry -c "
    SELECT 
        username,
        action,
        count(*) as frequency,
        array_agg(DISTINCT environment) as environments,
        min(timestamp) as first_access,
        max(timestamp) as last_access
    FROM audit_log
    WHERE (domain LIKE '%payment%' OR domain LIKE '%transaction%')
    AND timestamp >= NOW() - INTERVAL '90 days'
    GROUP BY username, action
    ORDER BY frequency DESC;"
}

# Run compliance reports
generate_gdpr_report > compliance_reports/gdpr_$(date +%Y%m%d).txt
generate_pci_report > compliance_reports/pci_dss_$(date +%Y%m%d).txt
EOF
```

## Disaster Recovery Operations

### Automated Disaster Recovery

```bash
# Disaster Recovery Automation
cat > scripts/disaster-recovery.sh << 'EOF'
#!/bin/bash

# Disaster recovery orchestration
execute_disaster_recovery() {
    local recovery_type=$1
    local target_region=$2
    
    echo "=== Executing Disaster Recovery ==="
    echo "Type: $recovery_type"
    echo "Target Region: $target_region"
    
    case $recovery_type in
        "failover")
            # Automated failover to secondary region
            echo "Initiating failover to $target_region..."
            
            # Update DNS records
            aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch file://failover-dns.json
            
            # Scale up services in target region
            kubectl --context $target_region scale deployment database-migrations --replicas=3
            
            # Verify service health
            for i in {1..30}; do
                if curl -f http://database-migrations.$target_region.gogidix-ecommerce.com/actuator/health; then
                    echo "Service healthy in target region"
                    break
                fi
                sleep 10
            done
            ;;
            
        "restore")
            # Point-in-time restore
            echo "Initiating point-in-time restore..."
            
            # Restore from backup
            restore_from_backup $target_region
            
            # Replay transactions
            replay_transactions $target_region
            
            # Verify data integrity
            verify_data_integrity $target_region
            ;;
    esac
}

# Backup restoration
restore_from_backup() {
    local region=$1
    local backup_timestamp=${2:-$(date -d '1 hour ago' +%Y%m%d%H%M)}
    
    echo "Restoring from backup: $backup_timestamp"
    
    # PostgreSQL restore
    aws s3 cp s3://gogidix-ecommerce-db-backups/postgresql/backup_$backup_timestamp.dump /tmp/
    pg_restore -h $POSTGRES_HOST_REPLICA -U $POSTGRES_USER -d migration_registry /tmp/backup_$backup_timestamp.dump
    
    # MongoDB restore
    aws s3 cp s3://gogidix-ecommerce-db-backups/mongodb/backup_$backup_timestamp.tar.gz /tmp/
    tar -xzf /tmp/backup_$backup_timestamp.tar.gz -C /tmp/
    mongorestore --host $MONGODB_HOST_REPLICA --username $MONGODB_USER --password $MONGODB_PASSWORD --authenticationDatabase admin /tmp/mongodb_backup/
    
    echo "Backup restoration completed"
}

# Data integrity verification
verify_data_integrity() {
    local region=$1
    
    echo "Verifying data integrity in $region..."
    
    # Check migration history consistency
    psql -h $POSTGRES_HOST_REPLICA -U $POSTGRES_USER -d migration_registry -c "
    SELECT 
        count(*) as total_migrations,
        count(DISTINCT domain) as unique_domains,
        max(executed_at) as latest_migration
    FROM migration_history;"
    
    # Verify checksums
    psql -h $POSTGRES_HOST_REPLICA -U $POSTGRES_USER -d migration_registry -c "
    SELECT 
        domain,
        version,
        checksum,
        CASE 
            WHEN checksum = expected_checksum THEN 'VALID'
            ELSE 'INVALID'
        END as checksum_status
    FROM migration_history
    WHERE executed_at >= NOW() - INTERVAL '24 hours'
    ORDER BY executed_at DESC;"
    
    echo "Data integrity verification completed"
}
EOF
```

## Documentation Management

### Automated Documentation Generation

```bash
# Automated Documentation System
cat > scripts/generate-docs.sh << 'EOF'
#!/bin/bash

# Generate comprehensive documentation
generate_documentation() {
    echo "=== Generating Documentation ==="
    
    # API Documentation
    curl -s http://localhost:8080/v3/api-docs | jq . > docs/api/openapi.json
    swagger-codegen generate -i docs/api/openapi.json -l html2 -o docs/api/html/
    
    # Schema Documentation
    generate_schema_documentation
    
    # Migration History Documentation
    generate_migration_history_docs
    
    # Performance Reports
    generate_performance_reports
    
    # Security Documentation
    generate_security_docs
}

# Schema documentation generation
generate_schema_documentation() {
    echo "Generating schema documentation..."
    
    # PostgreSQL schemas
    for domain in social-commerce warehousing courier-services centralized-dashboard; do
        pg_dump -h $POSTGRES_HOST -U $POSTGRES_USER -d ${domain//-/_} --schema-only > docs/schemas/postgresql/${domain}-schema.sql
        
        # Generate ERD
        postgresql_autodoc -h $POSTGRES_HOST -u $POSTGRES_USER -d ${domain//-/_} --file=docs/schemas/postgresql/${domain}-erd
    done
    
    # MongoDB schemas
    for database in warehousing analytics; do
        mongo --host $MONGODB_HOST --username $MONGODB_USER --password $MONGODB_PASSWORD --authenticationDatabase admin $database --eval "
        db.runCommand('listCollections').cursor.firstBatch.forEach(
            function(collection) {
                print('=== ' + collection.name + ' ===');
                printjson(db.getCollection(collection.name).findOne());
            }
        )" > docs/schemas/mongodb/${database}-schema.js
    done
}

# Performance documentation
generate_performance_reports() {
    echo "Generating performance reports..."
    
    # Migration performance trends
    psql -h $POSTGRES_HOST -U $POSTGRES_USER -d migration_registry -c "
    COPY (
        SELECT 
            domain,
            date_trunc('day', executed_at) as day,
            count(*) as migrations_count,
            avg(execution_time_ms) as avg_execution_time,
            max(execution_time_ms) as max_execution_time,
            min(execution_time_ms) as min_execution_time
        FROM migration_history
        WHERE executed_at >= NOW() - INTERVAL '30 days'
        GROUP BY domain, date_trunc('day', executed_at)
        ORDER BY day DESC, domain
    ) TO STDOUT WITH CSV HEADER" > docs/reports/performance_trends.csv
    
    # Generate performance charts
    python3 scripts/generate_charts.py docs/reports/performance_trends.csv docs/reports/performance_charts.html
}
EOF
```

### Schema Documentation

Maintain up-to-date schema documentation:

1. **Generate schema documentation**:
   ```bash
   # Create schema documentation script
   cat > scripts/generate-schema-docs.sh << EOF
   #!/bin/bash
   
   # PostgreSQL schema documentation
   schemaspy -t pgsql -db social_commerce -host \${POSTGRES_HOST} -port \${POSTGRES_PORT} \
     -u \${POSTGRES_USER} -p \${POSTGRES_PASSWORD} -o docs/schemas/postgresql/social_commerce
   
   schemaspy -t pgsql -db warehousing -host \${POSTGRES_HOST} -port \${POSTGRES_PORT} \
     -u \${POSTGRES_USER} -p \${POSTGRES_PASSWORD} -o docs/schemas/postgresql/warehousing
   
   # MongoDB schema documentation
   mongodoc -u \${MONGODB_USER} -p \${MONGODB_PASSWORD} --host \${MONGODB_HOST} \
     --db warehousing --out docs/schemas/mongodb/warehousing
   
   # Generate index documentation
   curl -s -X GET "http://\${ELASTICSEARCH_HOST}:\${ELASTICSEARCH_PORT}/_cat/indices?v" > docs/schemas/elasticsearch/indices.txt
   
   for index in \$(curl -s -X GET "http://\${ELASTICSEARCH_HOST}:\${ELASTICSEARCH_PORT}/_cat/indices" | awk '{print \$3}'); do
     curl -s -X GET "http://\${ELASTICSEARCH_HOST}:\${ELASTICSEARCH_PORT}/\${index}/_mapping" | \
       jq > docs/schemas/elasticsearch/\${index}-mapping.json
   done
   EOF
   
   # Make script executable
   chmod +x scripts/generate-schema-docs.sh
   
   # Generate documentation
   ./scripts/generate-schema-docs.sh
   ```

2. **Create migration documentation templates**:
   ```bash
   # Create template for migration documentation
   cat > templates/migration-doc-template.md << EOF
   # Migration: {version} - {description}
   
   ## Purpose
   
   [Describe the purpose of this migration]
   
   ## Changes
   
   - [List the schema changes made]
   - [Include DDL statements]
   - [Include DML statements if data is modified]
   
   ## Impact
   
   - [Describe impact on applications]
   - [Note any potential performance impacts]
   - [Identify affected services]
   
   ## Dependencies
   
   - [List required prior migrations]
   - [List migrations that depend on this one]
   
   ## Rollback Procedure
   
   ```sql
   -- Rollback SQL statements
   ```
   EOF
   ```

3. **Update documentation after migrations**:
   ```bash
   # Create post-migration documentation update script
   cat > scripts/update-docs-post-migration.sh << EOF
   #!/bin/bash
   
   # Parameters
   domain=\$1
   version=\$2
   
   # Generate updated schema documentation
   ./scripts/generate-schema-docs.sh \$domain
   
   # Update migration history documentation
   curl -s -X GET "http://localhost:8080/api/v1/migrations/history?domain=\$domain&format=markdown" \
     > docs/migrations/\$domain/history.md
   
   # Commit documentation changes
   git add docs/
   git commit -m "docs: Update schema documentation after \$domain v\$version migration"
   git push origin main
   EOF
   
   # Make script executable
   chmod +x scripts/update-docs-post-migration.sh
   ```

### Migration Standards

Document and enforce migration standards:

1. **Create migration standards documentation**:
   ```bash
   # Create standards documentation
   cat > docs/standards/migration-standards.md << EOF
   # Database Migration Standards
   
   ## Naming Conventions
   
   ### Migration Files
   
   - Format: `V{major}_{minor}_{patch}__{description}.sql`
   - Example: `V1_2_0__add_product_categories.sql`
   
   ### Database Objects
   
   - Tables: snake_case, plural (e.g., `products`, `order_items`)
   - Columns: snake_case (e.g., `product_id`, `created_at`)
   - Indexes: `idx_{table}_{columns}` (e.g., `idx_products_category_id`)
   - Constraints: `fk_{table}_{reference}` (e.g., `fk_order_items_products`)
   - Functions: snake_case, verb_noun (e.g., `calculate_total`, `update_timestamp`)
   
   ## SQL Standards
   
   ### PostgreSQL
   
   - Always specify schema name in DDL statements
   - Use IF EXISTS/IF NOT EXISTS clauses for idempotence
   - Add comments to tables and columns
   - Include proper indexes for foreign keys
   - Set NOT NULL constraint for required fields
   - Define proper data types and lengths
   - Use CHECK constraints for data validation
   
   ### MongoDB
   
   - Use JSON Schema validators for collections
   - Define indexes explicitly
   - Use consistent document structures
   - Include timestamps for all documents
   - Document all schema changes
   
   ## Migration Best Practices
   
   - One change per migration
   - Make migrations reversible when possible
   - Avoid large data migrations in schema changes
   - Test migrations in development before promotion
   - Document all migrations thoroughly
   - Include rollback procedures
   - Consider performance impact
   
   ## Security Standards
   
   - Never store sensitive data in plain text
   - Use encryption for sensitive fields
   - Implement proper access controls
   - Audit all schema changes
   - Follow least privilege principle
   
   ## Performance Standards
   
   - Use appropriate indexes
   - Consider query patterns when designing schema
   - Optimize for read or write operations based on usage
   - Avoid expensive operations during peak hours
   - Use batching for large data operations
   - Monitor performance impact of schema changes
   EOF
   ```

2. **Create migration template generator**:
   ```bash
   # Create migration template generator script
   cat > scripts/generate-migration.sh << EOF
   #!/bin/bash
   
   # Check parameters
   if [ \$# -lt 4 ]; then
     echo "Usage: \$0 <domain> <technology> <version> <description>"
     echo "Example: \$0 social-commerce postgresql 1.2.0 add_product_categories"
     exit 1
   fi
   
   domain=\$1
   tech=\$2
   version=\$3
   description=\$4
   
   # Create migration directory if it doesn't exist
   mkdir -p src/main/resources/db/migration/\$tech/\$domain
   
   # Create migration file
   migration_file="src/main/resources/db/migration/\$tech/\$domain/V\${version}__\${description}.\${tech}"
   
   case \$tech in
     postgresql)
       cat > \$migration_file << ENDSQL
   -- Migration: Add \$(echo \$description | tr '_' ' ')
   -- Domain: \$domain
   -- Version: \$version
   
   -- Description:
   -- [Add detailed description of the changes]
   
   -- Schema changes:
   
   -- Table changes:
   
   -- Index changes:
   
   -- Data migrations:
   
   -- Rollback:
   -- [Add rollback SQL statements as comments for documentation]
   ENDSQL
       ;;
     
     mongodb)
       cat > \$migration_file << ENDJS
   // Migration: Add \$(echo \$description | tr '_' ' ')
   // Domain: \$domain
   // Version: \$version
   
   // Description:
   // [Add detailed description of the changes]
   
   // Schema changes:
   
   // Collection changes:
   
   // Index changes:
   
   // Data migrations:
   
   // Rollback:
   // [Add rollback JavaScript statements as comments for documentation]
   ENDJS
       ;;
       
     # Add cases for other technologies...
   esac
   
   # Create documentation file
   doc_dir="docs/migrations/\$domain"
   mkdir -p \$doc_dir
   
   doc_file="\$doc_dir/V\${version}__\${description}.md"
   
   cat > \$doc_file << ENDMD
   # Migration: \$version - \$(echo \$description | tr '_' ' ')
   
   ## Purpose
   
   [Describe the purpose of this migration]
   
   ## Changes
   
   - [List the schema changes made]
   - [Include DDL statements]
   - [Include DML statements if data is modified]
   
   ## Impact
   
   - [Describe impact on applications]
   - [Note any potential performance impacts]
   - [Identify affected services]
   
   ## Dependencies
   
   - [List required prior migrations]
   - [List migrations that depend on this one]
   
   ## Rollback Procedure
   
   \`\`\`sql
   -- Rollback SQL statements
   \`\`\`
   ENDMD
   
   echo "Created migration file: \$migration_file"
   echo "Created documentation file: \$doc_file"
   EOF
   
   # Make script executable
   chmod +x scripts/generate-migration.sh
   ```

3. **Enforce standards through validation**:
   ```bash
   # Create migration validator script
   cat > scripts/validate-migration-standards.sh << EOF
   #!/bin/bash
   
   # Check parameters
   if [ \$# -lt 1 ]; then
     echo "Usage: \$0 <migration_file>"
     exit 1
   fi
   
   migration_file=\$1
   
   # Check file naming convention
   if [[ ! \$(basename \$migration_file) =~ ^V[0-9]+_[0-9]+_[0-9]+__[a-z0-9_]+\.(sql|js|lua|json)$ ]]; then
     echo "ERROR: Migration filename does not follow convention: V{major}_{minor}_{patch}__{description}.{ext}"
     exit 1
   fi
   
   # Check for documentation
   version=\$(basename \$migration_file | sed -E 's/V([0-9]+_[0-9]+_[0-9]+)__.*/\\1/')
   description=\$(basename \$migration_file | sed -E 's/V[0-9]+_[0-9]+_[0-9]+__([a-z0-9_]+)\..*/\\1/')
   domain=\$(echo \$migration_file | sed -E 's/.*db\/migration\/[a-z]+\/([a-z-]+)\/.*/\\1/')
   
   doc_file="docs/migrations/\$domain/V\${version}__\${description}.md"
   
   if [ ! -f \$doc_file ]; then
     echo "ERROR: Documentation file missing: \$doc_file"
     exit 1
   fi
   
   # Check file extension to determine technology
   ext=\${migration_file##*.}
   
   case \$ext in
     sql)
       # PostgreSQL-specific checks
       if ! grep -q "-- Description:" \$migration_file; then
         echo "ERROR: Missing description comment in SQL migration"
         exit 1
       fi
       
       if ! grep -q "-- Rollback:" \$migration_file; then
         echo "ERROR: Missing rollback instructions in SQL migration"
         exit 1
       fi
       
       # Check for schema name in DDL
       if grep -E "CREATE TABLE [^.]+" \$migration_file; then
         echo "WARNING: CREATE TABLE statement missing schema name"
       fi
       
       # Check for IF EXISTS/IF NOT EXISTS
       if grep -E "DROP TABLE [^IF]" \$migration_file; then
         echo "WARNING: DROP TABLE missing IF EXISTS clause"
       fi
       
       if grep -E "CREATE TABLE [^IF]" \$migration_file; then
         echo "WARNING: CREATE TABLE missing IF NOT EXISTS clause"
       fi
       ;;
     
     js)
       # MongoDB-specific checks
       if ! grep -q "// Description:" \$migration_file; then
         echo "ERROR: Missing description comment in MongoDB migration"
         exit 1
       fi
       
       if ! grep -q "// Rollback:" \$migration_file; then
         echo "ERROR: Missing rollback instructions in MongoDB migration"
         exit 1
       fi
       ;;
       
     # Add cases for other technologies...
   esac
   
   echo "Migration file passes standards validation"
   exit 0
   EOF
   
   # Make script executable
   chmod +x scripts/validate-migration-standards.sh
   ```

## Appendix

### Useful Commands

```bash
# Check migration status
curl -X GET "http://localhost:8080/api/v1/migrations/status?domain=social-commerce&environment=production" \
  -H "Authorization: Bearer ${TOKEN}"

# Validate migration without executing
./mvnw verify -Pmigration-validate -Dmigration.environment=production -Dmigration.domain=social-commerce

# Execute specific migration
./mvnw verify -Pmigration-execute -Dmigration.environment=production -Dmigration.domain=social-commerce -Dmigration.version=1.3.0

# Generate migration history report
curl -X GET "http://localhost:8080/api/v1/migrations/history?domain=social-commerce&environment=production&format=csv" \
  -H "Authorization: Bearer ${TOKEN}" > migration_history.csv

# Repair failed migration
curl -X POST "http://localhost:8080/api/v1/migrations/repair" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "domain": "social-commerce",
    "environment": "production",
    "version": "1.3.0",
    "status": "SUCCESS"
  }'

# Rollback migration
curl -X POST "http://localhost:8080/api/v1/migrations/rollback" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d '{
    "domain": "social-commerce",
    "environment": "production",
    "version": "1.3.0",
    "rollbackScript": "ALTER TABLE social_commerce.products DROP COLUMN IF EXISTS has_variants; DROP TABLE IF EXISTS social_commerce.product_variants;"
  }'

# Generate new migration
./scripts/generate-migration.sh social-commerce postgresql 1.4.0 add_product_attributes

# Check service health
curl -X GET "http://localhost:8080/actuator/health" \
  -H "Authorization: Bearer ${TOKEN}"

# Get service metrics
curl -X GET "http://localhost:8080/actuator/metrics" \
  -H "Authorization: Bearer ${TOKEN}"

# Get specific metric
curl -X GET "http://localhost:8080/actuator/metrics/migration.execution" \
  -H "Authorization: Bearer ${TOKEN}"
```

### Reference Documents

- [Database Migration Strategies](https://gogidix-ecommerce.com/docs/database/migration-strategies)
- [Zero-Downtime Migration Patterns](https://gogidix-ecommerce.com/docs/database/zero-downtime-patterns)
- [Database Security Standards](https://gogidix-ecommerce.com/docs/security/database-security)
- [Microservices Database Patterns](https://gogidix-ecommerce.com/docs/architecture/microservices-databases)
- [PostgreSQL Performance Optimization](https://gogidix-ecommerce.com/docs/database/postgresql-optimization)
- [MongoDB Schema Design](https://gogidix-ecommerce.com/docs/database/mongodb-schema-design)
- [Elasticsearch Index Management](https://gogidix-ecommerce.com/docs/database/elasticsearch-indices)
- [Redis Data Structure Design](https://gogidix-ecommerce.com/docs/database/redis-design-patterns)

### Glossary

- **Migration**: A versioned change to database schema or data
- **Schema**: The structure of a database, including tables, columns, and constraints
- **DDL**: Data Definition Language, SQL statements for defining database structures
- **DML**: Data Manipulation Language, SQL statements for manipulating data
- **Idempotent**: An operation that produces the same result regardless of how many times it is executed
- **Rollback**: The process of reverting a migration to its previous state
- **Flyway**: A database migration tool for version control of database schemas
- **Liquibase**: A database change management tool that supports multiple database types
- **Zero-Downtime Migration**: A migration strategy that allows schema changes without service interruption
- **Sharding**: Horizontal partitioning of data across multiple databases
- **Index**: A database structure that improves the speed of data retrieval operations
- **Partition**: A division of a logical database into distinct independent parts
- **GDPR**: General Data Protection Regulation, EU regulation on data protection and privacy
- **POPIA**: Protection of Personal Information Act, South African data protection law
- **PCI DSS**: Payment Card Industry Data Security Standard, security standard for payment processing
