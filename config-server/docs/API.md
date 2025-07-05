# Configuration Server API Documentation

This document outlines the REST API endpoints provided by the Configuration Server for managing application configurations across the Social E-commerce Ecosystem.

## API Overview

The Configuration Server exposes RESTful endpoints for:

1. Retrieving application configurations
2. Encrypting and decrypting sensitive values
3. Managing Git repository operations
4. Monitoring service health and metrics
5. Refreshing configuration in client applications

## Base URL

```
https://config-server.gogidix-ecommerce.com
```

## Authentication

All API endpoints require authentication. The following authentication methods are supported:

1. **OAuth2/JWT Authentication**: Bearer token in Authorization header
2. **Basic Authentication**: For service-to-service communication
3. **Certificate-based Authentication**: For secure system-to-system communication

Example:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Configuration Endpoints

### Retrieve Application Configuration

Retrieves configuration properties for an application in a specific environment.

**Endpoint**: `/{application}/{profile}[/{label}]`

**Method**: GET

**URL Parameters**:
- `application`: Name of the application
- `profile`: Environment profile (e.g., dev, test, stage, prod)
- `label` (optional): Git branch, tag, or commit ID (defaults to main)

**Response Format**: JSON or YAML (based on Accept header)

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/product-service/prod \
  -H 'Authorization: Bearer {token}' \
  -H 'Accept: application/json'
```

**Example Response**:
```json
{
  "name": "product-service",
  "profiles": ["prod"],
  "label": "main",
  "version": "8c71ae879914b5faf13ab8a4df2c574fc2374935",
  "state": null,
  "propertySources": [
    {
      "name": "https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository/service-domains/social-commerce/product-service-prod.yml",
      "source": {
        "server.port": 8080,
        "spring.datasource.url": "jdbc:postgresql://db.gogidix-ecommerce.com:5432/product_db",
        "spring.datasource.username": "product_service",
        "spring.datasource.password": "{cipher}AQAn6k0hWxPy7CJ+..."
      }
    },
    {
      "name": "https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository/service-domains/social-commerce/product-service.yml",
      "source": {
        "server.tomcat.threads.max": 200,
        "server.tomcat.threads.min-spare": 20,
        "management.endpoints.web.exposure.include": "health,info,metrics"
      }
    },
    {
      "name": "https://github.com/gogidix-social-ecommerce-ecosystem/configuration-repository/application.yml",
      "source": {
        "logging.level.root": "INFO",
        "logging.pattern.console": "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
      }
    }
  ]
}
```

### Retrieve Configuration Properties

Retrieves a flat representation of all configuration properties for an application.

**Endpoint**: `/{application}/{profile}[/{label}]/properties`

**Method**: GET

**URL Parameters**:
- `application`: Name of the application
- `profile`: Environment profile (e.g., dev, test, stage, prod)
- `label` (optional): Git branch, tag, or commit ID (defaults to main)

**Response Format**: Properties (plain text)

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/product-service/prod/properties \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```properties
server.port=8080
spring.datasource.url=jdbc:postgresql://db.gogidix-ecommerce.com:5432/product_db
spring.datasource.username=product_service
spring.datasource.password={cipher}AQAn6k0hWxPy7CJ+...
server.tomcat.threads.max=200
server.tomcat.threads.min-spare=20
management.endpoints.web.exposure.include=health,info,metrics
logging.level.root=INFO
logging.pattern.console=%d{yyyy-MM-dd HH:mm:ss} - %msg%n
```

### Retrieve Specific Property

Retrieves a specific property for an application.

**Endpoint**: `/{application}/{profile}[/{label}]/{property}`

**Method**: GET

**URL Parameters**:
- `application`: Name of the application
- `profile`: Environment profile (e.g., dev, test, stage, prod)
- `label` (optional): Git branch, tag, or commit ID (defaults to main)
- `property`: The specific property key to retrieve

**Response Format**: Text (property value)

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/product-service/prod/server.port \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```
8080
```

## Encryption Endpoints

### Encrypt Value

Encrypts a sensitive value using the server's encryption key.

**Endpoint**: `/encrypt`

**Method**: POST

**Request Body**: Raw text value to encrypt

**Response**: Encrypted value

**Example Request**:
```bash
curl -X POST \
  https://config-server.gogidix-ecommerce.com/encrypt \
  -H 'Authorization: Bearer {token}' \
  -d 'sensitive-password-value'
```

**Example Response**:
```
AQAn6k0hWxPy7CJ+ZcSH1McQbFZT0cmKwjqRzLw2qf4ZPH4Cg/EsQIk+zFLJ2tGHKdX2zUveqw==
```

### Decrypt Value

Decrypts an encrypted value using the server's encryption key.

**Endpoint**: `/decrypt`

**Method**: POST

**Request Body**: Encrypted value (without the '{cipher}' prefix)

**Response**: Decrypted value

**Example Request**:
```bash
curl -X POST \
  https://config-server.gogidix-ecommerce.com/decrypt \
  -H 'Authorization: Bearer {token}' \
  -d 'AQAn6k0hWxPy7CJ+ZcSH1McQbFZT0cmKwjqRzLw2qf4ZPH4Cg/EsQIk+zFLJ2tGHKdX2zUveqw=='
```

**Example Response**:
```
sensitive-password-value
```

## Git Repository Operations

### Refresh Repository

Forces a refresh of the Git repository.

**Endpoint**: `/actuator/busrefresh`

**Method**: POST

**Response**: HTTP 204 No Content

**Example Request**:
```bash
curl -X POST \
  https://config-server.gogidix-ecommerce.com/actuator/busrefresh \
  -H 'Authorization: Bearer {token}'
```

### List Repository Branches

Lists all branches in the Git repository.

**Endpoint**: `/repo/branches`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/repo/branches \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "branches": [
    "main",
    "develop",
    "feature/new-payment-service",
    "bugfix/cors-issue"
  ]
}
```

### List Repository Tags

Lists all tags in the Git repository.

**Endpoint**: `/repo/tags`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/repo/tags \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "tags": [
    "v1.0.0",
    "v1.1.0",
    "v2.0.0",
    "release-candidate-1"
  ]
}
```

## Monitor and Management Endpoints

### Health Check

Retrieves the health status of the Configuration Server.

**Endpoint**: `/actuator/health`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/actuator/health \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "status": "UP",
  "components": {
    "diskSpace": {
      "status": "UP",
      "details": {
        "total": 42949672960,
        "free": 21474836480,
        "threshold": 10485760,
        "exists": true
      }
    },
    "git": {
      "status": "UP",
      "details": {
        "commit": {
          "id": "8c71ae8",
          "time": "2023-06-15T10:30:45Z"
        }
      }
    },
    "refreshScope": {
      "status": "UP"
    },
    "db": {
      "status": "UP",
      "details": {
        "database": "PostgreSQL",
        "validationQuery": "isValid()"
      }
    }
  }
}
```

### Service Information

Retrieves information about the Configuration Server.

**Endpoint**: `/actuator/info`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/actuator/info \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "app": {
    "name": "config-server",
    "description": "Centralized Configuration Server",
    "version": "2.0.1",
    "encoding": "UTF-8",
    "java": {
      "version": "17.0.6",
      "vendor": "Eclipse Adoptium"
    }
  },
  "git": {
    "commit": {
      "id": "8c71ae8",
      "time": "2023-06-15T10:30:45Z"
    },
    "branch": "main"
  }
}
```

### Metrics

Retrieves metrics about the Configuration Server.

**Endpoint**: `/actuator/metrics`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/actuator/metrics \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "names": [
    "jvm.memory.used",
    "jvm.memory.max",
    "http.server.requests",
    "system.cpu.usage",
    "jvm.gc.memory.allocated",
    "jvm.gc.memory.promoted",
    "system.load.average.1m",
    "jvm.memory.committed",
    "system.cpu.count",
    "logback.events",
    "jvm.buffer.memory.used",
    "tomcat.sessions.created",
    "jvm.threads.daemon",
    "process.uptime",
    "tomcat.sessions.expired",
    "jvm.gc.max.data.size",
    "jvm.gc.pause",
    "jvm.gc.live.data.size",
    "jvm.buffer.count",
    "jvm.threads.live",
    "jvm.threads.peak",
    "process.cpu.usage"
  ]
}
```

### Specific Metric

Retrieves a specific metric.

**Endpoint**: `/actuator/metrics/{metric.name}`

**Method**: GET

**URL Parameters**:
- `metric.name`: Name of the metric to retrieve

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/actuator/metrics/http.server.requests \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "name": "http.server.requests",
  "description": "Duration of HTTP server request handling",
  "baseUnit": "seconds",
  "measurements": [
    {
      "statistic": "COUNT",
      "value": 5925
    },
    {
      "statistic": "TOTAL_TIME",
      "value": 114.59988
    },
    {
      "statistic": "MAX",
      "value": 2.943
    }
  ],
  "availableTags": [
    {
      "tag": "exception",
      "values": [
        "None",
        "IllegalArgumentException"
      ]
    },
    {
      "tag": "method",
      "values": [
        "GET",
        "POST"
      ]
    },
    {
      "tag": "uri",
      "values": [
        "/actuator/health",
        "/actuator/info",
        "/{application}/{profile}",
        "/encrypt",
        "/decrypt"
      ]
    },
    {
      "tag": "outcome",
      "values": [
        "SUCCESS",
        "CLIENT_ERROR",
        "SERVER_ERROR"
      ]
    },
    {
      "tag": "status",
      "values": [
        "200",
        "404",
        "500"
      ]
    }
  ]
}
```

### Environment Information

Retrieves the current environment configuration.

**Endpoint**: `/actuator/env`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  https://config-server.gogidix-ecommerce.com/actuator/env \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
{
  "activeProfiles": [
    "git",
    "prod"
  ],
  "propertySources": [
    {
      "name": "server.ports",
      "properties": {
        "local.server.port": {
          "value": 8888
        }
      }
    },
    {
      "name": "systemProperties",
      "properties": {
        "java.runtime.name": {
          "value": "OpenJDK Runtime Environment"
        },
        "java.version": {
          "value": "17.0.6"
        }
      }
    },
    {
      "name": "systemEnvironment",
      "properties": {
        "SPRING_PROFILES_ACTIVE": {
          "value": "git,prod",
          "origin": "System Environment Property \"SPRING_PROFILES_ACTIVE\""
        }
      }
    }
  ]
}
```

## Client Application Endpoints

### Refresh Client Configuration

Triggers a refresh of configuration in client applications.

**Endpoint**: `/actuator/refresh`

**Method**: POST

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  https://client-application.gogidix-ecommerce.com/actuator/refresh \
  -H 'Authorization: Bearer {token}'
```

**Example Response**:
```json
[
  "config.client.version",
  "spring.datasource.password"
]
```

### Refresh All Clients

Triggers a refresh of configuration in all client applications.

**Endpoint**: `/actuator/busrefresh`

**Method**: POST

**Response**: HTTP 204 No Content

**Example Request**:
```bash
curl -X POST \
  https://config-server.gogidix-ecommerce.com/actuator/busrefresh \
  -H 'Authorization: Bearer {token}'
```

## Error Handling

### Error Responses

All API errors return a standardized JSON response:

```json
{
  "timestamp": "2023-06-15T14:30:45.123Z",
  "status": 404,
  "error": "Not Found",
  "message": "Configuration for application 'unknown-service' with profile 'prod' not found",
  "path": "/unknown-service/prod"
}
```

### Common Error Codes

| Status Code | Description |
|------------|-------------|
| 400 | Bad Request - Invalid request format |
| 401 | Unauthorized - Authentication failed |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Configuration or resource not found |
| 409 | Conflict - Resource conflict |
| 422 | Unprocessable Entity - Invalid configuration data |
| 500 | Internal Server Error - Server-side error |
| 503 | Service Unavailable - Git repository unavailable |

## Rate Limiting

The Configuration Server implements rate limiting to prevent abuse:

- 100 requests per minute per client for regular endpoints
- 20 requests per minute per client for encryption/decryption endpoints
- 10 requests per minute per client for management endpoints

When rate limits are exceeded, the server returns a 429 Too Many Requests response.

## API Versioning

The Configuration Server API uses HTTP headers for versioning:

```
Accept: application/vnd.gogidix-ecommerce.v1+json
```

Current API versions:
- v1: Current stable version
- v2: Beta release with enhanced features

## Integration Examples

### Spring Boot Client Configuration

Configure a Spring Boot client to use the Configuration Server:

```yaml
# bootstrap.yml
spring:
  application:
    name: product-service
  cloud:
    config:
      uri: https://config-server.gogidix-ecommerce.com
      username: ${CONFIG_USER}
      password: ${CONFIG_PASSWORD}
      label: main
      fail-fast: true
      retry:
        initial-interval: 1000
        multiplier: 1.5
        max-attempts: 6
        max-interval: 2000
```

### Manual Configuration Refresh

Refresh configuration in a client application:

```java
@RestController
public class ConfigController {
    
    @Autowired
    private ContextRefresher contextRefresher;
    
    @PostMapping("/refresh")
    public Set<String> refreshConfig() {
        return contextRefresher.refresh();
    }
}
```

### Accessing Encrypted Properties

Configure a client to use encrypted properties:

```yaml
# application.yml
spring:
  datasource:
    url: jdbc:postgresql://db.gogidix-ecommerce.com:5432/product_db
    username: product_service
    password: '{cipher}AQAn6k0hWxPy7CJ+ZcSH1McQbFZT0cmKwjqRzLw2qf4ZPH4Cg/EsQIk+zFLJ2tGHKdX2zUveqw=='
```

### Shell Script Integration

Use curl to retrieve configuration properties in a shell script:

```bash
#!/bin/bash

# Get configuration properties
CONFIG=$(curl -s -X GET \
  https://config-server.gogidix-ecommerce.com/product-service/prod/properties \
  -H "Authorization: Bearer ${TOKEN}")

# Extract database URL
DB_URL=$(echo "$CONFIG" | grep "^spring.datasource.url" | cut -d= -f2-)

# Extract database username
DB_USERNAME=$(echo "$CONFIG" | grep "^spring.datasource.username" | cut -d= -f2-)

echo "Database URL: $DB_URL"
echo "Database Username: $DB_USERNAME"
```

## Best Practices

1. **Environment-Specific Profiles**: Use different profiles (dev, test, stage, prod) for environment-specific configuration.

2. **Security**: Always encrypt sensitive values using the `/encrypt` endpoint.

3. **Client Resilience**: Configure clients with retry mechanisms and fail-fast options for resilience.

4. **Caching**: Implement client-side caching to reduce load on the Configuration Server.

5. **Monitoring**: Use actuator endpoints to monitor the health and metrics of the Configuration Server.

6. **Configuration Isolation**: Organize configuration files by application and domain to maintain separation of concerns.

7. **Version Control**: Tag stable configurations in the Git repository for consistent deployments.

## Appendix

### Configuration Property Sources

The Configuration Server uses the following property sources in order of precedence:

1. Application-specific profile properties (`{application}-{profile}.yml`)
2. Application-specific properties (`{application}.yml`)
3. Profile-specific default properties (`application-{profile}.yml`)
4. Default properties (`application.yml`)

### Supported Formats

The Configuration Server supports the following configuration formats:

- YAML (.yml, .yaml)
- Properties (.properties)
- JSON (.json)

### Security Considerations

1. **Transport Security**: Always use HTTPS for all communication with the Configuration Server.
2. **Authentication**: Use OAuth2/JWT tokens for authentication instead of basic authentication when possible.
3. **Encryption**: Use the encryption features for all sensitive data.
4. **Access Control**: Implement fine-grained access control for different configurations.
5. **Auditing**: Enable audit logging for all configuration changes.

### Related Documentation

- [Spring Cloud Config Server Documentation](https://docs.spring.io/spring-cloud-config/docs/current/reference/html/)
- [Spring Boot Actuator Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/actuator.html)
- [OAuth2 Integration Guide](../security/oauth2-integration.md)
- [Configuration Best Practices Guide](../operations/configuration-best-practices.md)
