# Database Migrations - Architecture

## Architecture Overview

The Database Migrations service provides a comprehensive framework for managing database schema changes across the entire Social E-commerce Ecosystem. This enterprise-grade system is designed for maximum reliability, scalability, and technology-agnostic operation while maintaining strict consistency and data integrity across multiple databases, environments, and regions.

### Key Architectural Principles

1. **Multi-Database Support**: Native support for PostgreSQL, MongoDB, Redis, and Elasticsearch
2. **Zero-Downtime Operations**: Advanced migration strategies for continuous availability
3. **Multi-Environment Coordination**: Seamless promotion between development, testing, staging, and production
4. **Multi-Region Consistency**: Global database schema synchronization with regional compliance
5. **Enterprise Security**: Role-based access control, audit logging, and compliance standards
6. **High Availability**: Distributed architecture with automatic failover and recovery
7. **Observability**: Comprehensive monitoring, alerting, and performance analytics

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                    Database Migrations Architecture                 │
│                                                                     │
├─────────────────┬───────────────────────┬─────────────────────────┤
│                 │                       │                         │
│ Migration Core  │ Database Technology   │ Environment Support     │
│                 │ Adapters              │                         │
│ - Schema Repo   │ - PostgreSQL          │ - Development           │
│ - Version Mgmt  │ - MongoDB             │ - Testing               │
│ - Migration     │ - Redis               │ - Staging               │
│   Execution     │ - Elasticsearch       │ - Production            │
│ - Validation    │                       │                         │
│                 │                       │                         │
├─────────────────┼───────────────────────┼─────────────────────────┤
│                 │                       │                         │
│ Security Layer  │ Integration Layer     │ Monitoring Layer        │
│                 │                       │                         │
│ - Credential    │ - CI/CD Integration   │ - Migration Metrics     │
│   Management    │ - Service Coordination│ - Performance Impact    │
│ - Access Control│ - Application         │ - Schema Validation     │
│ - Audit Logging │   Frameworks          │ - Error Detection       │
│                 │                       │                         │
└─────────────────┴───────────────────────┴─────────────────────────┘
```

## Component Design

### Migration Core

The Migration Core manages the fundamental aspects of database schema changes:

1. **Schema Repository**:
   - Git-based schema definition storage
   - Schema versioning with semantic versioning
   - Change history tracking
   - Branch-based schema development

2. **Version Management**:
   - Schema version tracking per environment
   - Dependency management between migrations
   - Schema baseline management
   - Version compatibility enforcement

3. **Migration Execution**:
   - Migration script execution
   - Transaction management
   - Error handling and recovery
   - Parallel migration coordination
   - Migration ordering and dependency resolution

4. **Schema Validation**:
   - Schema syntax validation
   - Performance impact assessment
   - Security vulnerability detection
   - Compliance standard verification

### Database Technology Adapters

Adapters provide technology-specific migration capabilities:

1. **PostgreSQL Adapter**:
   - Flyway integration for SQL migrations
   - Liquibase support for complex migrations
   - DDL and DML script management
   - Function, procedure, and trigger management
   - Index optimization
   - Partitioning support

2. **MongoDB Adapter**:
   - Schema evolution for schemaless databases
   - Collection and index management
   - Document structure transformations
   - Aggregation pipeline updates
   - Sharding configuration

3. **Redis Adapter**:
   - Data structure evolution
   - Key naming scheme management
   - Index management
   - Expiration policy updates
   - Cluster configuration

4. **Elasticsearch Adapter**:
   - Index mapping management
   - Analyzer and tokenizer configuration
   - Reindexing operations
   - Alias management
   - Template updates

### Environment Support

Environment-specific migration configurations and strategies:

1. **Development Environment**:
   - Rapid iteration support
   - Developer-friendly tooling
   - Local database support
   - Integration with development workflows

2. **Testing Environment**:
   - Test database initialization
   - Test data management
   - Integration test support
   - Migration verification

3. **Staging Environment**:
   - Production-like configuration
   - Performance testing
   - Final validation before production
   - Rehearsal of production migrations

4. **Production Environment**:
   - Zero-downtime migration strategies
   - Rollback preparation
   - Performance impact minimization
   - High-availability considerations
   - Regional deployment coordination

### Security Layer

The Security Layer ensures secure handling of database operations:

1. **Credential Management**:
   - Secure storage of database credentials
   - Environment-specific credential management
   - Integration with secrets management service
   - Credential rotation support

2. **Access Control**:
   - Role-based access control for migrations
   - Permission management for schema changes
   - Approval workflows for sensitive operations
   - Environment-based access restrictions

3. **Audit Logging**:
   - Comprehensive logging of all schema changes
   - User attribution for schema modifications
   - Timestamp recording for all operations
   - Compliance with audit requirements

### Integration Layer

The Integration Layer connects the migration system with other services:

1. **CI/CD Integration**:
   - Automated migration execution in pipelines
   - Version control integration
   - Build tool plugins
   - Deployment coordination

2. **Service Coordination**:
   - Cross-service migration orchestration
   - Dependency management between service migrations
   - Communication with affected services
   - Downtime coordination

3. **Application Framework Integration**:
   - Spring Boot integration
   - JPA/Hibernate support
   - MongoDB ODM integration
   - Custom framework adapters

### Monitoring Layer

The Monitoring Layer provides visibility into migration operations:

1. **Migration Metrics**:
   - Migration duration tracking
   - Success/failure rates
   - Schema size and complexity metrics
   - Migration frequency analysis

2. **Performance Impact Analysis**:
   - Query performance monitoring
   - Index effectiveness evaluation
   - Resource utilization tracking
   - Transaction throughput impact assessment

3. **Schema Validation Monitoring**:
   - Ongoing schema validation
   - Drift detection
   - Standard compliance verification
   - Security vulnerability monitoring

4. **Error Detection**:
   - Failed migration detection
   - Schema inconsistency identification
   - Data integrity validation
   - Performance regression detection

## Migration Workflow

The database migration process follows a standardized workflow:

```
┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│            │    │            │    │            │    │            │
│  Develop   ├───►│  Validate  ├───►│   Review   ├───►│   Approve  │
│            │    │            │    │            │    │            │
└────────────┘    └────────────┘    └────────────┘    └────────────┘
                                                             │
                                                             ▼
┌────────────┐    ┌────────────┐    ┌────────────┐    ┌────────────┐
│            │    │            │    │            │    │            │
│  Monitor   │◄───┤   Execute  │◄───┤  Schedule  │◄───┤   Plan     │
│            │    │            │    │            │    │            │
└────────────┘    └────────────┘    └────────────┘    └────────────┘
```

1. **Development Stage**:
   - Create migration scripts
   - Test migrations locally
   - Commit to version control
   - Document changes

2. **Validation Stage**:
   - Syntax validation
   - Schema standards verification
   - Performance impact assessment
   - Security and compliance checking

3. **Review Stage**:
   - Peer review of migration scripts
   - Cross-team review for wide-impact changes
   - Database administrator review for complex migrations
   - Documentation review

4. **Approval Stage**:
   - Approval workflow based on impact assessment
   - Environment-specific approvals
   - Compliance sign-off for regulated changes
   - Change management integration

5. **Planning Stage**:
   - Scheduling of migration execution
   - Dependency resolution
   - Resource allocation
   - Communication planning

6. **Scheduling Stage**:
   - Coordination with deployment windows
   - Notification to affected teams
   - Preparation of rollback plan
   - Integration with deployment pipelines

7. **Execution Stage**:
   - Automated execution via CI/CD
   - Transaction management
   - Error handling
   - Rollback preparation

8. **Monitoring Stage**:
   - Performance monitoring
   - Success verification
   - Post-migration validation
   - Application impact assessment

## Directory Structure

The database migrations are organized with the following directory structure:

```
database-migrations/
├── common/                         # Common database objects shared across domains
│   ├── functions/                  # Shared database functions
│   ├── types/                      # Shared custom data types
│   └── utilities/                  # Utility scripts and helpers
├── domains/                        # Domain-specific migrations
│   ├── social-commerce/            # Social Commerce domain migrations
│   │   ├── postgresql/             # PostgreSQL migrations for Social Commerce
│   │   │   ├── schemas/            # Schema definitions
│   │   │   ├── tables/             # Table definitions and alterations
│   │   │   ├── functions/          # Domain-specific functions
│   │   │   ├── views/              # View definitions
│   │   │   └── indexes/            # Index definitions
│   │   ├── mongodb/                # MongoDB migrations for Social Commerce
│   │   │   ├── collections/        # Collection definitions
│   │   │   ├── indexes/            # Index definitions
│   │   │   └── transforms/         # Document transformation scripts
│   │   └── elasticsearch/          # Elasticsearch migrations for Social Commerce
│   │       ├── indexes/            # Index definitions
│   │       ├── mappings/           # Mapping configurations
│   │       └── templates/          # Index templates
│   ├── warehousing/                # Warehousing domain migrations
│   ├── courier-services/           # Courier Services domain migrations
│   └── centralized-dashboard/      # Centralized Dashboard domain migrations
├── environments/                   # Environment-specific configurations
│   ├── development/                # Development environment configuration
│   ├── testing/                    # Testing environment configuration
│   ├── staging/                    # Staging environment configuration
│   └── production/                 # Production environment configuration
├── tools/                          # Migration tools and utilities
│   ├── validation/                 # Schema validation tools
│   ├── generators/                 # Migration script generators
│   ├── performance/                # Performance analysis tools
│   └── monitoring/                 # Migration monitoring utilities
└── templates/                      # Migration script templates
    ├── postgresql/                 # PostgreSQL migration templates
    ├── mongodb/                    # MongoDB migration templates
    ├── redis/                      # Redis migration templates
    └── elasticsearch/              # Elasticsearch migration templates
```

## Technology-specific Implementation

### PostgreSQL Implementation

For PostgreSQL databases, the migration architecture uses:

1. **Flyway as Primary Tool**:
   - SQL-based migrations
   - Versioned migration scripts
   - Repeatable migrations for views and functions
   - Checksum validation

2. **Liquibase for Complex Cases**:
   - XML/YAML-based change sets
   - Database-agnostic definitions
   - Complex refactorings
   - Precondition support

3. **Migration Strategy**:
   - Forward-only migrations by default
   - Transactional migrations when possible
   - Statement batching for performance
   - Pre/post-migration validation

4. **Script Naming Convention**:
   ```
   V{version}__{description}.sql
   R__{description}.sql
   ```

### MongoDB Implementation

For MongoDB databases, the architecture uses:

1. **Custom MongoDB Migration Framework**:
   - JavaScript-based migrations
   - Document transformation scripts
   - Index management
   - Collection operations

2. **Migration Strategy**:
   - Schema evolution for flexible documents
   - Incremental data transformations
   - Parallel processing for large collections
   - Background index creation

3. **Script Naming Convention**:
   ```
   {version}-{description}.js
   ```

### Redis Implementation

For Redis databases, the architecture uses:

1. **Redis Migration Scripts**:
   - Lua scripts for atomic operations
   - Key pattern transformations
   - Data structure conversions
   - TTL management

2. **Migration Strategy**:
   - In-place data transformations when possible
   - Dual-write approach for non-atomic changes
   - Bulk operations for performance
   - Gradual key migration

3. **Script Naming Convention**:
   ```
   {version}-{description}.lua
   ```

### Elasticsearch Implementation

For Elasticsearch, the architecture uses:

1. **Elasticsearch Migration Framework**:
   - Index template management
   - Reindexing operations
   - Alias switching for zero-downtime
   - Mapping updates

2. **Migration Strategy**:
   - Blue-green index deployment
   - Rolling upgrades
   - Reindexing with transforms
   - Alias management for transparent transitions

3. **Script Naming Convention**:
   ```
   {version}-{description}.json
   ```

## Multi-Environment Architecture

The migration system supports different environments with specific considerations:

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Migration Configuration                       │
└───────────────────────────┬───────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            │                               │
  ┌─────────▼─────────┐          ┌──────────▼──────────┐
  │                   │          │                     │
  │  Development      │          │   Production        │
  │  Environment      │          │   Environment       │
  │                   │          │                     │
  └───────────────────┘          └─────────────────────┘
  │                   │          │                     │
  │ ┌───────────────┐ │          │ ┌───────────────┐  │
  │ │Auto-migration │ │          │ │Scheduled      │  │
  │ │on startup     │ │          │ │migrations     │  │
  │ └───────────────┘ │          │ └───────────────┘  │
  │                   │          │                     │
  │ ┌───────────────┐ │          │ ┌───────────────┐  │
  │ │Developer tools│ │          │ │Zero-downtime  │  │
  │ │integration    │ │          │ │strategies     │  │
  │ └───────────────┘ │          │ └───────────────┘  │
  │                   │          │                     │
  └───────────────────┘          └─────────────────────┘
```

1. **Development Environment**:
   - Automatic migration on application startup
   - Developer tools integration
   - Database reset capabilities
   - Comprehensive schema generation
   - Fast feedback loop

2. **Testing Environment**:
   - Automated test database initialization
   - Test data population
   - Consistent database state for tests
   - Performance testing configurations
   - Parallel test database support

3. **Staging Environment**:
   - Production-like migration process
   - Complete rehearsal of production migrations
   - Performance validation
   - Application compatibility testing
   - Migration timing measurements

4. **Production Environment**:
   - Zero-downtime migration strategies
   - Scheduled migration windows
   - Gradual rollout capabilities
   - Automated verification
   - Rollback preparation
   - Regional coordination

## Multi-Region Architecture

The system supports multi-region database deployments:

```
┌─────────────────────────────────────────────────────────────────────┐
│                       Global Migration Coordinator                  │
└───────────────────────────┬───────────────────────────────────────┘
                            │
                 ┌──────────┴──────────┐
                 │                     │
       ┌─────────▼─────────┐ ┌─────────▼─────────┐
       │                   │ │                   │
       │  Europe Region    │ │   Africa Region   │
       │  Migrations       │ │   Migrations      │
       │                   │ │                   │
       └─────────┬─────────┘ └─────────┬─────────┘
                 │                     │
     ┌───────────┴───────┐   ┌─────────┴───────┐
     │                   │   │                 │
┌────▼─────┐       ┌─────▼───┐ ┌─────▼───┐ ┌───▼─────┐
│          │       │         │ │         │ │         │
│ Western  │       │ Eastern │ │ North   │ │ Sub-    │
│ Europe   │       │ Europe  │ │ Africa  │ │ Saharan │
│ Database │       │ Database│ │ Database│ │ Database│
│          │       │         │ │         │ │         │
└──────────┘       └─────────┘ └─────────┘ └─────────┘
```

1. **Global Migration Coordination**:
   - Centralized migration orchestration
   - Region-specific execution
   - Cross-region dependency management
   - Sequenced regional rollout

2. **Region-Specific Adapters**:
   - Region-specific configuration
   - Local database connections
   - Regional compliance adaptations
   - Performance tuning for regional infrastructure

3. **Migration Strategies**:
   - Sequential region migration for global consistency
   - Parallel region migration for independent schemas
   - Region fallback capabilities
   - Cross-region data consistency validation

## Security Architecture

Database migrations include comprehensive security measures:

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                        Migration Security                           │
│                                                                     │
├─────────────────┬───────────────────────┬─────────────────────────┤
│                 │                       │                         │
│ Authentication  │ Authorization         │ Encryption              │
│                 │                       │                         │
│ - Database      │ - Role-based          │ - Connection            │
│   Credentials   │   Access Control      │   Encryption            │
│ - Service       │ - Environment         │ - Credential            │
│   Accounts      │   Restrictions        │   Encryption            │
│ - CI/CD         │ - Approval            │ - Sensitive Data        │
│   Integration   │   Workflows           │   Handling              │
│                 │                       │                         │
├─────────────────┼───────────────────────┼─────────────────────────┤
│                 │                       │                         │
│ Audit           │ Vulnerability         │ Compliance              │
│                 │ Prevention            │                         │
│ - Change        │ - SQL Injection       │ - PCI DSS               │
│   Logging       │   Prevention          │ - GDPR                  │
│ - User          │ - Schema Validation   │ - SOX                   │
│   Attribution   │ - Security Scanning   │ - ISO 27001             │
│ - Timestamp     │ - Penetration         │ - Industry              │
│   Recording     │   Testing             │   Regulations           │
│                 │                       │                         │
└─────────────────┴───────────────────────┴─────────────────────────┘
```

1. **Authentication**:
   - Database credential management
   - Service account management
   - Temporary credential generation
   - CI/CD authentication integration

2. **Authorization**:
   - Role-based access control for migrations
   - Environment-based permissions
   - Schema-level access control
   - Operation-specific permissions

3. **Encryption**:
   - Encrypted database connections
   - Credential encryption at rest
   - Sensitive data handling in migrations
   - Secure parameter passing

4. **Audit**:
   - Comprehensive change logging
   - User attribution for all changes
   - Timestamp recording
   - Immutable audit records

5. **Vulnerability Prevention**:
   - SQL injection prevention
   - Input validation
   - Prepared statements
   - Schema validation
   - Security scanning integration

6. **Compliance**:
   - PCI DSS compliance for payment data
   - GDPR compliance for personal data
   - SOX compliance for financial systems
   - Industry-specific regulation compliance

## Integration Points

The Database Migrations service integrates with multiple ecosystem components:

1. **Config Server**:
   - Environment-specific database configurations
   - Migration settings
   - Feature toggles
   - Connection parameters

2. **Secrets Management**:
   - Database credentials
   - Authentication tokens
   - Encryption keys
   - Sensitive configuration values

3. **CI/CD Pipeline**:
   - Automated migration execution
   - Migration validation
   - Pipeline integration
   - Deployment coordination

4. **Service Registry**:
   - Service discovery for affected applications
   - Dependency tracking
   - Service availability checking
   - Application registry

5. **Monitoring System**:
   - Migration execution metrics
   - Performance impact monitoring
   - Error detection
   - Success verification

6. **Logging Service**:
   - Centralized migration logging
   - Audit trail recording
   - Error reporting
   - Execution history

## Performance Considerations

The migration system is designed with performance in mind:

1. **Migration Optimization**:
   - Batched operations
   - Parallel execution where safe
   - Optimized locking strategies
   - Transaction management

2. **Database Impact Minimization**:
   - Low-impact migration scheduling
   - Resource utilization control
   - Background operations
   - Gradual changes

3. **Scalability**:
   - Horizontal scaling for migration coordinators
   - Distributed execution
   - Load balancing
   - Resource pooling

4. **Resource Management**:
   - Connection pooling
   - Statement caching
   - Memory optimization
   - Execution timeouts

## Resilience Patterns

To ensure high reliability, the following resilience patterns are implemented:

1. **Migration Validation**:
   - Pre-execution validation
   - Post-execution verification
   - Schema comparison
   - Data integrity checks

2. **Transactional Execution**:
   - All-or-nothing execution when possible
   - Savepoints for complex migrations
   - Partial success handling
   - Cleanup operations

3. **Error Recovery**:
   - Automatic retry for transient failures
   - Manual intervention protocols
   - State recovery mechanisms
   - Failure documentation

4. **Rollback Strategies**:
   - Automated rollback for failures
   - Manual rollback procedures
   - Point-in-time recovery integration
   - State preservation

## Advanced Enterprise Features

### AI-Powered Migration Intelligence

1. **Intelligent Schema Analysis**:
   - ML-based schema optimization recommendations
   - Performance impact prediction using historical data
   - Automatic detection of schema anti-patterns
   - Risk assessment for large-scale migrations

2. **Predictive Analytics**:
   - Migration execution time prediction
   - Resource usage forecasting
   - Bottleneck identification and resolution
   - Capacity planning for database growth

3. **Automated Code Generation**:
   - Smart migration script generation from schema diffs
   - Rollback script auto-generation
   - Test data generation for migration validation
   - Documentation auto-generation

### Enterprise Compliance Framework

1. **Regulatory Compliance**:
   - GDPR compliance for European operations
   - POPIA compliance for African markets
   - PCI DSS for payment data protection
   - SOX compliance for financial controls
   - HIPAA readiness for healthcare data

2. **Data Governance**:
   - Data lineage tracking across migrations
   - Data classification and sensitivity labeling
   - Retention policy enforcement
   - Privacy impact assessment integration

3. **Audit and Compliance Reporting**:
   - Automated compliance reports
   - Risk assessment dashboards
   - Regulatory change impact analysis
   - Compliance violation detection and alerting

### Enterprise Integration Capabilities

1. **Service Mesh Integration**:
   - Istio service mesh compatibility
   - Distributed tracing with Jaeger
   - Circuit breaker patterns
   - Load balancing and failover

2. **Event-Driven Architecture**:
   - Kafka-based event streaming
   - CQRS pattern implementation
   - Event sourcing for audit trails
   - Saga pattern for distributed transactions

3. **API Gateway Integration**:
   - Kong/Istio gateway compatibility
   - Rate limiting and throttling
   - API versioning and deprecation
   - Security policy enforcement

## Future Enhancements

Strategic roadmap for advanced capabilities:

1. **AI-Assisted Schema Design**:
   - Schema optimization recommendations using machine learning
   - Performance impact prediction with 95% accuracy
   - Automatic migration script generation from natural language
   - Schema evolution suggestions based on usage patterns

2. **Enhanced Zero-Downtime Strategies**:
   - Advanced schema change patterns with <1ms downtime
   - Dynamic view switching with real-time data sync
   - Shadow table techniques for large table migrations
   - Online schema change tools integration (pt-online-schema-change)

3. **Multi-Database Consistency**:
   - Cross-database transaction support with 2PC protocol
   - Polyglot persistence strategies with automatic data mapping
   - Consistency verification tools with real-time monitoring
   - Data synchronization mechanisms with conflict resolution

4. **Automated Performance Tuning**:
   - Index recommendation engine with ML-based optimization
   - Query optimization suggestions with cost-based analysis
   - Storage optimization with automatic compression and partitioning
   - Automatic partition management with usage-based scaling

## Appendix: Migration Strategy Patterns

### Zero-Downtime Migration Patterns

1. **Expand and Contract Pattern**:
   ```
   // 1. Add new column alongside old column
   ALTER TABLE users ADD COLUMN full_name VARCHAR(255);

   // 2. Application writes to both columns
   // (Dual-write implemented in application layer)

   // 3. Migrate data from old columns to new column
   UPDATE users SET full_name = first_name || ' ' || last_name 
   WHERE full_name IS NULL;

   // 4. Application switches to reading from new column
   // (Feature toggle flipped in application)

   // 5. Drop old columns when safe
   ALTER TABLE users DROP COLUMN first_name, DROP COLUMN last_name;
   ```

2. **View Switching Pattern**:
   ```
   // 1. Create new table with desired schema
   CREATE TABLE users_new (
     id SERIAL PRIMARY KEY,
     username VARCHAR(50) NOT NULL,
     email VARCHAR(255) NOT NULL,
     full_name VARCHAR(255) NOT NULL
   );

   // 2. Create or update view to point to old table
   CREATE OR REPLACE VIEW users_view AS SELECT * FROM users;

   // 3. Migrate data to new table
   INSERT INTO users_new (id, username, email, full_name)
   SELECT id, username, email, first_name || ' ' || last_name FROM users;

   // 4. Switch view to point to new table
   CREATE OR REPLACE VIEW users_view AS SELECT * FROM users_new;

   // 5. Applications use the view instead of direct table access
   // (Applications configured to use users_view)

   // 6. Drop old table when safe
   DROP TABLE users;
   
   // 7. Rename new table to original name
   ALTER TABLE users_new RENAME TO users;
   
   // 8. Update view to use renamed table
   CREATE OR REPLACE VIEW users_view AS SELECT * FROM users;
   ```

3. **Temporary Table Pattern**:
   ```
   // 1. Lock table briefly to create consistent snapshot
   LOCK TABLE orders IN SHARE MODE;
   
   // 2. Create temporary table with desired structure
   CREATE TEMPORARY TABLE temp_orders AS SELECT * FROM orders;
   
   // 3. Release lock
   COMMIT;
   
   // 4. Perform transformations on temporary table
   ALTER TABLE temp_orders ADD COLUMN status_code INT;
   UPDATE temp_orders SET status_code = 
     CASE status 
       WHEN 'pending' THEN 1 
       WHEN 'processing' THEN 2 
       WHEN 'completed' THEN 3 
       ELSE 0 
     END;
   
   // 5. Lock original table briefly for swap
   LOCK TABLE orders IN EXCLUSIVE MODE;
   
   // 6. Swap tables (technique varies by database)
   ALTER TABLE orders RENAME TO orders_old;
   ALTER TABLE temp_orders RENAME TO orders;
   
   // 7. Release lock
   COMMIT;
   
   // 8. Clean up old table when safe
   DROP TABLE orders_old;
   ```

### MongoDB Migration Patterns

1. **Document Transformation Pattern**:
   ```javascript
   // Migrate user documents to add fullName field
   db.users.find({fullName: {$exists: false}}).forEach(function(user) {
     db.users.updateOne(
       {_id: user._id},
       {
         $set: {fullName: user.firstName + ' ' + user.lastName},
         $currentDate: {lastModified: true}
       }
     );
   });
   ```

2. **Schema Version Pattern**:
   ```javascript
   // Add schema version to all documents
   db.products.updateMany(
     {schemaVersion: {$exists: false}},
     {
       $set: {schemaVersion: 1},
       $currentDate: {lastModified: true}
     }
   );
   
   // Migrate documents from version 1 to version 2
   db.products.find({schemaVersion: 1}).forEach(function(product) {
     // Transform document
     product.price = {
       amount: product.price,
       currency: 'USD'
     };
     product.schemaVersion = 2;
     product.lastModified = new Date();
     
     // Save updated document
     db.products.replaceOne({_id: product._id}, product);
   });
   ```

### Elasticsearch Migration Patterns

1. **Reindex Pattern**:
   ```json
   // 1. Create new index with updated mapping
   PUT /products_v2
   {
     "mappings": {
       "properties": {
         "name": {"type": "text", "analyzer": "english"},
         "description": {"type": "text", "analyzer": "english"},
         "price": {"type": "float"},
         "category": {"type": "keyword"},
         "tags": {"type": "keyword"}
       }
     }
   }
   
   // 2. Reindex data from old index to new index
   POST /_reindex
   {
     "source": {
       "index": "products_v1"
     },
     "dest": {
       "index": "products_v2"
     },
     "script": {
       "source": "ctx._source.tags = ctx._source.remove('keywords')"
     }
   }
   
   // 3. Create or update alias
   POST /_aliases
   {
     "actions": [
       {"remove": {"index": "products_v1", "alias": "products"}},
       {"add": {"index": "products_v2", "alias": "products"}}
     ]
   }
   
   // 4. Applications use the alias instead of direct index name
   // (Applications configured to use "products" alias)
   
   // 5. Delete old index when safe
   DELETE /products_v1
   ```

2. **Template Update Pattern**:
   ```json
   // 1. Update index template
   PUT /_template/logs_template
   {
     "index_patterns": ["logs-*"],
     "mappings": {
       "properties": {
         "timestamp": {"type": "date"},
         "message": {"type": "text"},
         "level": {"type": "keyword"},
         "service": {"type": "keyword"},
         "trace_id": {"type": "keyword"},
         "duration_ms": {"type": "integer"}
       }
     }
   }
   
   // 2. New indices will use updated template
   // 3. For existing indices, reindex as needed
   ```

### Redis Migration Patterns

1. **Key Renaming Pattern**:
   ```lua
   -- Scan and rename keys from old pattern to new pattern
   local cursor = 0
   local oldPattern = "user:*:profile"
   local count = 0
   
   repeat
     local result = redis.call("SCAN", cursor, "MATCH", oldPattern)
     cursor = tonumber(result[1])
     local keys = result[2]
     
     for i, oldKey in ipairs(keys) do
       local userId = string.match(oldKey, "user:(.+):profile")
       local newKey = "user_profile:" .. userId
       redis.call("RENAME", oldKey, newKey)
       count = count + 1
     end
   until cursor == 0
   
   return count
   ```

2. **Data Structure Conversion Pattern**:
   ```lua
   -- Convert simple string counters to hash fields
   local cursor = 0
   local pattern = "counter:*"
   local count = 0
   
   repeat
     local result = redis.call("SCAN", cursor, "MATCH", pattern)
     cursor = tonumber(result[1])
     local keys = result[2]
     
     for i, key in ipairs(keys) do
       local entityId = string.match(key, "counter:(.+)")
       local value = redis.call("GET", key)
       
       -- Create hash with counter value
       redis.call("HSET", "counters", entityId, value)
       
       -- Delete old key
       redis.call("DEL", key)
       count = count + 1
     end
   until cursor == 0
   
   return count
   ```
