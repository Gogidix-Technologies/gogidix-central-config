# CI/CD Templates - API Documentation

This document outlines the APIs provided by the CI/CD Templates service for programmatic interaction with the template system.

## API Overview

The CI/CD Templates service exposes REST APIs for:

1. Template retrieval and management
2. Workflow generation and customization
3. Template usage analytics
4. Service integration and status
5. Pipeline monitoring and control

## Base URL

```
https://cicd-api.exalt-ecommerce.com/v1
```

## Authentication

All API endpoints require authentication. The following authentication methods are supported:

1. **OAuth2/JWT Authentication**: Bearer token in Authorization header
2. **API Key Authentication**: API key in X-API-Key header
3. **Service-to-Service Authentication**: Client credentials with mutual TLS

Example:
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

## Template Management Endpoints

### List Available Templates

Retrieves a list of all available CI/CD templates.

**Endpoint**: `/templates`

**Method**: GET

**Query Parameters**:
- `category` (optional): Filter templates by category (build, test, deploy, etc.)
- `technology` (optional): Filter templates by technology (java, node, react, etc.)
- `page` (optional): Page number for pagination (default: 1)
- `limit` (optional): Number of items per page (default: 20)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/templates?category=build&technology=java" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "total": 5,
  "page": 1,
  "limit": 20,
  "templates": [
    {
      "id": "java-maven-build",
      "name": "Java Maven Build",
      "category": "build",
      "technology": "java",
      "path": "templates/build/java-maven-build.yml",
      "version": "1.2.3",
      "description": "Standard build template for Java Maven projects",
      "last_updated": "2023-06-15T10:30:00Z"
    },
    {
      "id": "java-gradle-build",
      "name": "Java Gradle Build",
      "category": "build",
      "technology": "java",
      "path": "templates/build/java-gradle-build.yml",
      "version": "1.1.0",
      "description": "Standard build template for Java Gradle projects",
      "last_updated": "2023-05-20T14:45:00Z"
    }
    // Additional templates...
  ]
}
```

### Get Template Details

Retrieves detailed information about a specific template.

**Endpoint**: `/templates/{template_id}`

**Method**: GET

**URL Parameters**:
- `template_id`: ID of the template to retrieve

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/templates/java-maven-build" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "id": "java-maven-build",
  "name": "Java Maven Build",
  "category": "build",
  "technology": "java",
  "path": "templates/build/java-maven-build.yml",
  "version": "1.2.3",
  "description": "Standard build template for Java Maven projects",
  "last_updated": "2023-06-15T10:30:00Z",
  "created_by": "devops-team",
  "inputs": [
    {
      "name": "java-version",
      "description": "Java version to use for the build",
      "type": "string",
      "required": false,
      "default": "17"
    },
    {
      "name": "maven-args",
      "description": "Additional Maven arguments",
      "type": "string",
      "required": false,
      "default": "-B -DskipTests"
    },
    {
      "name": "artifact-path",
      "description": "Path to build artifacts",
      "type": "string",
      "required": true
    }
  ],
  "outputs": [
    {
      "name": "build-status",
      "description": "Status of the build",
      "type": "string"
    },
    {
      "name": "artifact-location",
      "description": "Location of the build artifacts",
      "type": "string"
    }
  ],
  "usage_count": 24,
  "success_rate": 92.5,
  "average_duration": 245,
  "dependencies": [
    "actions/checkout@v3",
    "actions/setup-java@v3",
    "actions/upload-artifact@v3"
  ]
}
```

### Get Template Content

Retrieves the actual YAML content of a template.

**Endpoint**: `/templates/{template_id}/content`

**Method**: GET

**URL Parameters**:
- `template_id`: ID of the template to retrieve

**Query Parameters**:
- `format` (optional): Response format (yaml or json, default: yaml)

**Response Format**: YAML or JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/templates/java-maven-build/content" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
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
    outputs:
      build-status:
        description: "Status of the build"
        value: ${{ jobs.build.outputs.status }}
      artifact-location:
        description: "Location of the build artifacts"
        value: ${{ jobs.build.outputs.artifact_location }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      status: ${{ steps.status.outputs.status }}
      artifact_location: ${{ steps.upload.outputs.artifact_location }}
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
      
      - name: Set status
        id: status
        run: echo "status=success" >> $GITHUB_OUTPUT
      
      - name: Upload build artifacts
        id: upload
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: ${{ inputs.artifact-path }}
```

### Create New Template

Creates a new CI/CD template.

**Endpoint**: `/templates`

**Method**: POST

**Request Body**: JSON object with template details and content

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/templates" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "custom-java-build",
    "name": "Custom Java Build",
    "category": "build",
    "technology": "java",
    "description": "Customized build template for Java projects",
    "content": "name: Custom Java Build\n\non:\n  workflow_call:\n    inputs:\n      java-version:\n        required: false\n        type: string\n        default: '\''17'\''\n..."
  }'
```

**Example Response**:
```json
{
  "id": "custom-java-build",
  "name": "Custom Java Build",
  "category": "build",
  "technology": "java",
  "path": "templates/build/custom-java-build.yml",
  "version": "1.0.0",
  "description": "Customized build template for Java projects",
  "created_at": "2023-06-20T15:30:00Z",
  "created_by": "devops-team"
}
```

### Update Template

Updates an existing CI/CD template.

**Endpoint**: `/templates/{template_id}`

**Method**: PUT

**URL Parameters**:
- `template_id`: ID of the template to update

**Request Body**: JSON object with updated template details and content

**Response Format**: JSON

**Example Request**:
```bash
curl -X PUT \
  "https://cicd-api.exalt-ecommerce.com/v1/templates/custom-java-build" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Custom Java Build",
    "description": "Updated customized build template for Java projects",
    "content": "name: Custom Java Build\n\non:\n  workflow_call:\n    inputs:\n      java-version:\n        required: false\n        type: string\n        default: '\''17'\''\n..."
  }'
```

**Example Response**:
```json
{
  "id": "custom-java-build",
  "name": "Custom Java Build",
  "category": "build",
  "technology": "java",
  "path": "templates/build/custom-java-build.yml",
  "version": "1.0.1",
  "description": "Updated customized build template for Java projects",
  "updated_at": "2023-06-21T09:15:00Z",
  "updated_by": "devops-team"
}
```

### Delete Template

Deletes a CI/CD template.

**Endpoint**: `/templates/{template_id}`

**Method**: DELETE

**URL Parameters**:
- `template_id`: ID of the template to delete

**Response Format**: JSON

**Example Request**:
```bash
curl -X DELETE \
  "https://cicd-api.exalt-ecommerce.com/v1/templates/custom-java-build" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "id": "custom-java-build",
  "status": "deleted",
  "message": "Template successfully deleted"
}
```

## Workflow Generation Endpoints

### Generate Workflow

Generates a complete workflow from template compositions.

**Endpoint**: `/workflows/generate`

**Method**: POST

**Request Body**: JSON object with workflow details and template selections

**Response Format**: JSON with YAML content

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/workflows/generate" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "service_name": "product-service",
    "service_type": "java",
    "domain": "social-commerce",
    "templates": [
      {
        "id": "java-maven-build",
        "inputs": {
          "java-version": "17",
          "maven-args": "-B -DskipTests",
          "artifact-path": "target/*.jar"
        }
      },
      {
        "id": "java-test",
        "inputs": {
          "java-version": "17",
          "test-command": "mvn test",
          "coverage-threshold": "80"
        }
      },
      {
        "id": "docker-build",
        "inputs": {
          "dockerfile-path": "Dockerfile",
          "image-name": "product-service",
          "image-tags": "latest"
        }
      }
    ],
    "environments": ["development", "production"],
    "branch_rules": {
      "main": ["production"],
      "develop": ["development"]
    }
  }'
```

**Example Response**:
```json
{
  "service_name": "product-service",
  "workflow_file": "product-service-pipeline.yml",
  "content": "name: Product Service CI/CD Pipeline\n\non:\n  push:\n    branches: [ main, develop ]\n  pull_request:\n    branches: [ main, develop ]\n\njobs:\n  build:\n    uses: ./.github/workflows/templates/build/java-maven-build.yml\n    with:\n      java-version: '17'\n      maven-args: '-B -DskipTests'\n      artifact-path: 'target/*.jar'\n  \n  test:\n    needs: build\n    uses: ./.github/workflows/templates/test/java-test.yml\n    with:\n      java-version: '17'\n      test-command: 'mvn test'\n      coverage-threshold: '80'\n  \n  package:\n    needs: [test]\n    uses: ./.github/workflows/templates/build/docker-build.yml\n    with:\n      dockerfile-path: 'Dockerfile'\n      image-name: 'product-service'\n      image-tags: 'latest'\n  \n  deploy-dev:\n    if: github.ref == 'refs/heads/develop'\n    needs: package\n    uses: ./.github/workflows/templates/deploy/kubernetes-deploy.yml\n    with:\n      environment: 'development'\n      namespace: 'social-commerce-dev'\n      deployment-strategy: 'rolling-update'\n      health-check-path: '/actuator/health'\n  \n  deploy-prod:\n    if: github.ref == 'refs/heads/main'\n    needs: package\n    uses: ./.github/workflows/templates/deploy/blue-green-deploy.yml\n    with:\n      environment: 'production'\n      namespace: 'social-commerce-prod'\n      health-check-path: '/actuator/health'\n      approval-required: true\n",
  "generated_at": "2023-06-20T14:30:00Z"
}
```

### Validate Workflow

Validates a workflow file against standards and best practices.

**Endpoint**: `/workflows/validate`

**Method**: POST

**Request Body**: JSON object with workflow content

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/workflows/validate" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "content": "name: Product Service CI/CD Pipeline\n\non:\n  push:\n    branches: [ main, develop ]\n  pull_request:\n    branches: [ main, develop ]\n\njobs:\n  build:\n    uses: ./.github/workflows/templates/build/java-maven-build.yml\n    with:\n      java-version: '\''17'\''\n      maven-args: '\''-B -DskipTests'\''\n      artifact-path: '\''target/*.jar'\''"
  }'
```

**Example Response**:
```json
{
  "valid": true,
  "warnings": [
    {
      "line": 15,
      "message": "No security scanning job defined in the workflow"
    }
  ],
  "suggestions": [
    {
      "type": "security",
      "message": "Add a security scanning job to the workflow",
      "template": "security/dependency-check"
    }
  ],
  "validated_at": "2023-06-20T14:35:00Z"
}
```

### Customize Template

Customizes a template for a specific service within allowed boundaries.

**Endpoint**: `/templates/{template_id}/customize`

**Method**: POST

**URL Parameters**:
- `template_id`: ID of the template to customize

**Request Body**: JSON object with customization details

**Response Format**: JSON with YAML content

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/templates/java-maven-build/customize" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "service_name": "product-service",
    "customizations": {
      "inputs": {
        "java-version": {
          "default": "17"
        },
        "maven-args": {
          "default": "-B -DskipTests -Pproduction"
        }
      },
      "steps": {
        "add": [
          {
            "name": "Cache Maven packages",
            "position": "after:checkout",
            "content": "uses: actions/cache@v3\nwith:\n  path: ~/.m2\n  key: ${{ runner.os }}-m2-${{ hashFiles(\"**/pom.xml\") }}\n  restore-keys: ${{ runner.os }}-m2"
          }
        ]
      }
    }
  }'
```

**Example Response**:
```json
{
  "template_id": "java-maven-build",
  "service_name": "product-service",
  "custom_template_id": "product-service-java-maven-build",
  "content": "name: Java Maven Build\n\non:\n  workflow_call:\n    inputs:\n      java-version:\n        required: false\n        type: string\n        default: '17'\n      maven-args:\n        required: false\n        type: string\n        default: '-B -DskipTests -Pproduction'\n      artifact-path:\n        required: true\n        type: string\n\njobs:\n  build:\n    runs-on: ubuntu-latest\n    steps:\n      - uses: actions/checkout@v3\n      \n      - name: Cache Maven packages\n        uses: actions/cache@v3\n        with:\n          path: ~/.m2\n          key: ${{ runner.os }}-m2-${{ hashFiles(\"**/pom.xml\") }}\n          restore-keys: ${{ runner.os }}-m2\n      \n      - name: Set up JDK\n        uses: actions/setup-java@v3\n        with:\n          java-version: ${{ inputs.java-version }}\n          distribution: 'temurin'\n          cache: 'maven'\n      \n      - name: Build with Maven\n        run: mvn ${{ inputs.maven-args }}\n      \n      - name: Upload build artifacts\n        uses: actions/upload-artifact@v3\n        with:\n          name: build-artifacts\n          path: ${{ inputs.artifact-path }}",
  "customized_at": "2023-06-20T15:00:00Z"
}
```

## Analytics Endpoints

### Template Usage Analytics

Retrieves usage analytics for templates.

**Endpoint**: `/analytics/templates/usage`

**Method**: GET

**Query Parameters**:
- `template_id` (optional): Filter by specific template
- `service_type` (optional): Filter by service type
- `domain` (optional): Filter by domain
- `start_date` (optional): Start date for analytics (default: 30 days ago)
- `end_date` (optional): End date for analytics (default: today)
- `group_by` (optional): Group results by (template, service, domain, day, week, month)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/analytics/templates/usage?template_id=java-maven-build&group_by=domain" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "template_id": "java-maven-build",
  "total_usage": 1240,
  "success_rate": 94.5,
  "average_duration": 230,
  "usage_by_domain": [
    {
      "domain": "social-commerce",
      "usage_count": 520,
      "success_rate": 95.2,
      "average_duration": 215
    },
    {
      "domain": "warehousing",
      "usage_count": 380,
      "success_rate": 93.8,
      "average_duration": 245
    },
    {
      "domain": "courier-services",
      "usage_count": 290,
      "success_rate": 94.1,
      "average_duration": 235
    },
    {
      "domain": "centralized-dashboard",
      "usage_count": 50,
      "success_rate": 96.0,
      "average_duration": 210
    }
  ],
  "time_period": {
    "start_date": "2023-05-21",
    "end_date": "2023-06-20"
  }
}
```

### Pipeline Performance Analytics

Retrieves performance analytics for CI/CD pipelines.

**Endpoint**: `/analytics/pipelines/performance`

**Method**: GET

**Query Parameters**:
- `service_name` (optional): Filter by specific service
- `domain` (optional): Filter by domain
- `environment` (optional): Filter by environment
- `start_date` (optional): Start date for analytics (default: 30 days ago)
- `end_date` (optional): End date for analytics (default: today)
- `group_by` (optional): Group results by (service, domain, environment, day, week, month)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/analytics/pipelines/performance?domain=social-commerce&environment=production" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "domain": "social-commerce",
  "environment": "production",
  "total_runs": 320,
  "success_rate": 96.5,
  "average_duration": 28.5,
  "average_deployment_frequency": "2.3 per day",
  "average_lead_time": "4.2 hours",
  "average_recovery_time": "45 minutes",
  "stages": [
    {
      "name": "build",
      "success_rate": 98.4,
      "average_duration": 5.2
    },
    {
      "name": "test",
      "success_rate": 97.2,
      "average_duration": 8.5
    },
    {
      "name": "security_scan",
      "success_rate": 96.8,
      "average_duration": 4.3
    },
    {
      "name": "deploy",
      "success_rate": 96.5,
      "average_duration": 10.5
    }
  ],
  "time_period": {
    "start_date": "2023-05-21",
    "end_date": "2023-06-20"
  }
}
```

### Deployment Analytics

Retrieves analytics for deployments.

**Endpoint**: `/analytics/deployments`

**Method**: GET

**Query Parameters**:
- `service_name` (optional): Filter by specific service
- `domain` (optional): Filter by domain
- `environment` (optional): Filter by environment
- `start_date` (optional): Start date for analytics (default: 30 days ago)
- `end_date` (optional): End date for analytics (default: today)
- `group_by` (optional): Group results by (service, domain, environment, day, week, month)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/analytics/deployments?environment=production" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "environment": "production",
  "total_deployments": 185,
  "success_rate": 97.8,
  "rollback_rate": 2.2,
  "average_deployment_time": 12.5,
  "deployments_by_domain": [
    {
      "domain": "social-commerce",
      "deployment_count": 78,
      "success_rate": 98.7,
      "rollback_rate": 1.3,
      "average_deployment_time": 11.2
    },
    {
      "domain": "warehousing",
      "deployment_count": 45,
      "success_rate": 97.8,
      "rollback_rate": 2.2,
      "average_deployment_time": 13.5
    },
    {
      "domain": "courier-services",
      "deployment_count": 42,
      "success_rate": 95.2,
      "rollback_rate": 4.8,
      "average_deployment_time": 14.8
    },
    {
      "domain": "centralized-dashboard",
      "deployment_count": 20,
      "success_rate": 100.0,
      "rollback_rate": 0.0,
      "average_deployment_time": 9.5
    }
  ],
  "deployment_strategies": {
    "rolling_update": 110,
    "blue_green": 55,
    "canary": 20
  },
  "time_period": {
    "start_date": "2023-05-21",
    "end_date": "2023-06-20"
  }
}
```

## Service Integration Endpoints

### Register Service

Registers a service for CI/CD template integration.

**Endpoint**: `/services`

**Method**: POST

**Request Body**: JSON object with service details

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/services" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "inventory-service",
    "repository": "exalt-social-ecommerce-ecosystem/inventory-service",
    "type": "java",
    "domain": "warehousing",
    "description": "Service for managing inventory",
    "contacts": ["warehousing-team@exalt-ecommerce.com"],
    "environments": ["development", "testing", "staging", "production"]
  }'
```

**Example Response**:
```json
{
  "id": "inventory-service",
  "repository": "exalt-social-ecommerce-ecosystem/inventory-service",
  "type": "java",
  "domain": "warehousing",
  "description": "Service for managing inventory",
  "contacts": ["warehousing-team@exalt-ecommerce.com"],
  "environments": ["development", "testing", "staging", "production"],
  "registered_at": "2023-06-20T16:45:00Z",
  "status": "registered",
  "integration_status": "pending"
}
```

### Get Service Integration Status

Retrieves the integration status of a service.

**Endpoint**: `/services/{service_id}/status`

**Method**: GET

**URL Parameters**:
- `service_id`: ID of the service to retrieve status for

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/services/inventory-service/status" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "id": "inventory-service",
  "repository": "exalt-social-ecommerce-ecosystem/inventory-service",
  "integration_status": "active",
  "templates_used": [
    "java-maven-build",
    "java-test",
    "sonarqube-analysis",
    "dependency-check",
    "docker-build",
    "kubernetes-deploy"
  ],
  "environments_configured": [
    "development",
    "testing",
    "staging",
    "production"
  ],
  "last_pipeline_run": {
    "id": "12345678",
    "status": "success",
    "started_at": "2023-06-20T15:30:00Z",
    "completed_at": "2023-06-20T15:45:00Z",
    "duration": 900
  },
  "customizations": [
    {
      "template_id": "java-maven-build",
      "custom_template_id": "inventory-service-java-maven-build"
    }
  ],
  "compliance": {
    "status": "compliant",
    "last_checked": "2023-06-20T16:00:00Z",
    "issues": []
  }
}
```

### Update Service Integration

Updates the integration configuration for a service.

**Endpoint**: `/services/{service_id}/integration`

**Method**: PUT

**URL Parameters**:
- `service_id`: ID of the service to update

**Request Body**: JSON object with integration configuration

**Response Format**: JSON

**Example Request**:
```bash
curl -X PUT \
  "https://cicd-api.exalt-ecommerce.com/v1/services/inventory-service/integration" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "templates": [
      {
        "id": "java-maven-build",
        "inputs": {
          "java-version": "17",
          "maven-args": "-B -DskipTests -Pproduction"
        }
      },
      {
        "id": "java-test",
        "inputs": {
          "java-version": "17",
          "test-command": "mvn verify",
          "coverage-threshold": "85"
        }
      }
    ],
    "environments": {
      "development": {
        "deployment_strategy": "rolling-update",
        "approval_required": false,
        "auto_deploy": true
      },
      "production": {
        "deployment_strategy": "blue-green",
        "approval_required": true,
        "approvers": ["warehousing-lead", "ops-team"],
        "auto_deploy": false
      }
    }
  }'
```

**Example Response**:
```json
{
  "id": "inventory-service",
  "repository": "exalt-social-ecommerce-ecosystem/inventory-service",
  "integration_status": "updated",
  "templates_configured": [
    "java-maven-build",
    "java-test"
  ],
  "environments_configured": [
    "development",
    "production"
  ],
  "updated_at": "2023-06-20T17:15:00Z",
  "workflow_file_updated": true,
  "next_steps": [
    "Commit workflow file to repository",
    "Run pipeline to verify configuration"
  ]
}
```

## Pipeline Management Endpoints

### Get Pipeline Status

Retrieves the status of a pipeline for a service.

**Endpoint**: `/pipelines/{service_id}/status`

**Method**: GET

**URL Parameters**:
- `service_id`: ID of the service

**Query Parameters**:
- `environment` (optional): Filter by environment
- `branch` (optional): Filter by branch
- `limit` (optional): Number of pipeline runs to return (default: 10)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/pipelines/inventory-service/status?environment=production&limit=5" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "service_id": "inventory-service",
  "environment": "production",
  "pipeline_runs": [
    {
      "id": "12345678",
      "branch": "main",
      "commit": "abcdef123456",
      "status": "success",
      "started_at": "2023-06-20T15:30:00Z",
      "completed_at": "2023-06-20T15:45:00Z",
      "duration": 900,
      "triggered_by": "John Doe",
      "stages": [
        {
          "name": "build",
          "status": "success",
          "duration": 180
        },
        {
          "name": "test",
          "status": "success",
          "duration": 320
        },
        {
          "name": "security_scan",
          "status": "success",
          "duration": 150
        },
        {
          "name": "deploy",
          "status": "success",
          "duration": 250
        }
      ]
    },
    {
      "id": "12345677",
      "branch": "main",
      "commit": "abcdef123455",
      "status": "success",
      "started_at": "2023-06-19T14:20:00Z",
      "completed_at": "2023-06-19T14:36:00Z",
      "duration": 960,
      "triggered_by": "Jane Smith",
      "stages": [
        {
          "name": "build",
          "status": "success",
          "duration": 185
        },
        {
          "name": "test",
          "status": "success",
          "duration": 340
        },
        {
          "name": "security_scan",
          "status": "success",
          "duration": 155
        },
        {
          "name": "deploy",
          "status": "success",
          "duration": 280
        }
      ]
    }
    // Additional pipeline runs...
  ]
}
```

### Trigger Pipeline

Triggers a pipeline run for a service.

**Endpoint**: `/pipelines/{service_id}/trigger`

**Method**: POST

**URL Parameters**:
- `service_id`: ID of the service

**Request Body**: JSON object with trigger parameters

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/pipelines/inventory-service/trigger" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "branch": "main",
    "commit": "abcdef123456",
    "environment": "production",
    "parameters": {
      "skip_tests": false,
      "debug_mode": true
    }
  }'
```

**Example Response**:
```json
{
  "service_id": "inventory-service",
  "pipeline_run_id": "12345679",
  "branch": "main",
  "commit": "abcdef123456",
  "environment": "production",
  "status": "triggered",
  "triggered_at": "2023-06-20T18:00:00Z",
  "triggered_by": "API",
  "parameters": {
    "skip_tests": false,
    "debug_mode": true
  },
  "monitoring_url": "https://github.com/exalt-social-ecommerce-ecosystem/inventory-service/actions/runs/12345679"
}
```

### Approve Deployment

Approves a pending deployment.

**Endpoint**: `/pipelines/{service_id}/approve`

**Method**: POST

**URL Parameters**:
- `service_id`: ID of the service

**Request Body**: JSON object with approval details

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/pipelines/inventory-service/approve" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "pipeline_run_id": "12345679",
    "environment": "production",
    "comment": "Approved for production deployment"
  }'
```

**Example Response**:
```json
{
  "service_id": "inventory-service",
  "pipeline_run_id": "12345679",
  "environment": "production",
  "approval_status": "approved",
  "approved_at": "2023-06-20T18:15:00Z",
  "approved_by": "John Doe",
  "comment": "Approved for production deployment",
  "deployment_status": "in_progress",
  "estimated_completion": "2023-06-20T18:30:00Z"
}
```

### Rollback Deployment

Initiates a rollback of a deployment.

**Endpoint**: `/pipelines/{service_id}/rollback`

**Method**: POST

**URL Parameters**:
- `service_id`: ID of the service

**Request Body**: JSON object with rollback details

**Response Format**: JSON

**Example Request**:
```bash
curl -X POST \
  "https://cicd-api.exalt-ecommerce.com/v1/pipelines/inventory-service/rollback" \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "environment": "production",
    "target_version": "1.2.3",
    "reason": "Performance degradation observed",
    "immediate": true
  }'
```

**Example Response**:
```json
{
  "service_id": "inventory-service",
  "environment": "production",
  "rollback_id": "rb-12345",
  "status": "initiated",
  "current_version": "1.3.0",
  "target_version": "1.2.3",
  "reason": "Performance degradation observed",
  "initiated_at": "2023-06-20T19:00:00Z",
  "initiated_by": "John Doe",
  "estimated_completion": "2023-06-20T19:15:00Z",
  "monitoring_url": "https://github.com/exalt-social-ecommerce-ecosystem/inventory-service/actions/runs/12345680"
}
```

## Health and Monitoring Endpoints

### System Health

Retrieves the health status of the CI/CD template system.

**Endpoint**: `/health`

**Method**: GET

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/health" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "status": "healthy",
  "version": "1.2.3",
  "uptime": "15d 6h 42m",
  "components": [
    {
      "name": "template_repository",
      "status": "healthy",
      "last_check": "2023-06-20T19:30:00Z"
    },
    {
      "name": "github_api",
      "status": "healthy",
      "last_check": "2023-06-20T19:30:00Z"
    },
    {
      "name": "database",
      "status": "healthy",
      "last_check": "2023-06-20T19:30:00Z"
    },
    {
      "name": "workflow_generator",
      "status": "healthy",
      "last_check": "2023-06-20T19:30:00Z"
    }
  ],
  "metrics": {
    "active_pipelines": 15,
    "templates_count": 42,
    "services_count": 87,
    "avg_response_time": 120
  }
}
```

### Runner Status

Retrieves the status of GitHub Actions runners.

**Endpoint**: `/runners/status`

**Method**: GET

**Query Parameters**:
- `group` (optional): Filter by runner group
- `status` (optional): Filter by status (online, offline)

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/runners/status?group=production-runners" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "total_runners": 15,
  "online_runners": 12,
  "offline_runners": 3,
  "busy_runners": 8,
  "runners": [
    {
      "id": "runner-1",
      "name": "prod-runner-01",
      "group": "production-runners",
      "status": "online",
      "busy": true,
      "labels": ["linux", "x64", "production"],
      "last_seen": "2023-06-20T19:35:00Z"
    },
    {
      "id": "runner-2",
      "name": "prod-runner-02",
      "group": "production-runners",
      "status": "online",
      "busy": false,
      "labels": ["linux", "x64", "production"],
      "last_seen": "2023-06-20T19:35:00Z"
    }
    // Additional runners...
  ]
}
```

### Active Pipelines

Retrieves information about currently running pipelines.

**Endpoint**: `/pipelines/active`

**Method**: GET

**Query Parameters**:
- `domain` (optional): Filter by domain
- `environment` (optional): Filter by environment

**Response Format**: JSON

**Example Request**:
```bash
curl -X GET \
  "https://cicd-api.exalt-ecommerce.com/v1/pipelines/active" \
  -H "Authorization: Bearer {token}"
```

**Example Response**:
```json
{
  "total_active": 8,
  "by_domain": {
    "social-commerce": 3,
    "warehousing": 2,
    "courier-services": 2,
    "centralized-dashboard": 1
  },
  "by_environment": {
    "development": 4,
    "testing": 2,
    "staging": 1,
    "production": 1
  },
  "active_pipelines": [
    {
      "service_id": "product-service",
      "pipeline_run_id": "12345681",
      "domain": "social-commerce",
      "environment": "development",
      "started_at": "2023-06-20T19:20:00Z",
      "current_stage": "test",
      "progress": 45,
      "estimated_completion": "2023-06-20T19:40:00Z"
    },
    {
      "service_id": "inventory-service",
      "pipeline_run_id": "12345682",
      "domain": "warehousing",
      "environment": "production",
      "started_at": "2023-06-20T19:25:00Z",
      "current_stage": "deploy",
      "progress": 75,
      "estimated_completion": "2023-06-20T19:45:00Z"
    }
    // Additional pipelines...
  ]
}
```

## Error Handling

### Error Responses

All API errors return a standardized JSON response:

```json
{
  "error": {
    "code": "INVALID_TEMPLATE",
    "message": "The template contains invalid YAML syntax",
    "details": {
      "line": 15,
      "column": 3,
      "reason": "mapping values are not allowed in this context"
    },
    "request_id": "req-12345abcde",
    "timestamp": "2023-06-20T15:45:00Z"
  }
}
```

### Common Error Codes

| Error Code | Description |
|------------|-------------|
| `AUTHENTICATION_ERROR` | Authentication failed |
| `AUTHORIZATION_ERROR` | Insufficient permissions |
| `INVALID_REQUEST` | Invalid request format |
| `INVALID_TEMPLATE` | Invalid template format |
| `TEMPLATE_NOT_FOUND` | Template not found |
| `SERVICE_NOT_FOUND` | Service not found |
| `PIPELINE_NOT_FOUND` | Pipeline not found |
| `VALIDATION_ERROR` | Validation failed |
| `GITHUB_API_ERROR` | GitHub API error |
| `WORKFLOW_GENERATION_ERROR` | Workflow generation failed |
| `RESOURCE_LIMIT_EXCEEDED` | Resource limit exceeded |
| `INTERNAL_SERVER_ERROR` | Internal server error |

## Rate Limiting

The API implements rate limiting to prevent abuse:

- 60 requests per minute per user for most endpoints
- 10 requests per minute for resource-intensive endpoints (workflow generation, analytics)
- 5 requests per minute for pipeline trigger endpoints

When rate limits are exceeded, the API returns a 429 Too Many Requests response with headers indicating the limit and when it will reset:

```
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 0
X-RateLimit-Reset: 1687287900
```

## Versioning

The API uses URL versioning to ensure backward compatibility:

- Current version: `v1`
- Beta version: `v2-beta`

To use a specific version, include it in the URL path:

```
https://cicd-api.exalt-ecommerce.com/v1/templates
https://cicd-api.exalt-ecommerce.com/v2-beta/templates
```

## Integration Examples

### Template Integration in Service Repository

To integrate templates into a service repository:

1. **Create Workflow Directory**:
   ```bash
   mkdir -p .github/workflows/templates
   ```

2. **Copy Templates**:
   ```bash
   curl -X GET "https://cicd-api.exalt-ecommerce.com/v1/templates/download?category=build,test,deploy" \
     -H "Authorization: Bearer {token}" \
     -o templates.zip
   
   unzip templates.zip -d .github/workflows/templates/
   ```

3. **Generate Workflow File**:
   ```bash
   curl -X POST \
     "https://cicd-api.exalt-ecommerce.com/v1/workflows/generate" \
     -H "Authorization: Bearer {token}" \
     -H "Content-Type: application/json" \
     -d '{
       "service_name": "product-service",
       "service_type": "java",
       "domain": "social-commerce",
       "templates": [
         {"id": "java-maven-build", "inputs": {...}},
         {"id": "java-test", "inputs": {...}}
       ]
     }' > .github/workflows/pipeline.yml
   ```

4. **Commit and Push**:
   ```bash
   git add .github/workflows
   git commit -m "Integrate standardized CI/CD templates"
   git push
   ```

### Monitoring Pipeline Status from CLI

Using the API to monitor pipeline status from a CLI tool:

```bash
#!/bin/bash

SERVICE_ID=$1
PIPELINE_ID=$2
TOKEN=$3

echo "Monitoring pipeline $PIPELINE_ID for service $SERVICE_ID..."

while true; do
  STATUS=$(curl -s -X GET \
    "https://cicd-api.exalt-ecommerce.com/v1/pipelines/$SERVICE_ID/status?pipeline_id=$PIPELINE_ID" \
    -H "Authorization: Bearer $TOKEN" | jq -r '.status')
  
  echo "Current status: $STATUS"
  
  if [[ "$STATUS" == "success" || "$STATUS" == "failed" || "$STATUS" == "cancelled" ]]; then
    echo "Pipeline completed with status: $STATUS"
    break
  fi
  
  sleep 10
done
```

### Bulk Template Update

Using the API to update templates across multiple services:

```javascript
// update-templates.js
const axios = require('axios');

const apiBaseUrl = 'https://cicd-api.exalt-ecommerce.com/v1';
const token = process.env.API_TOKEN;

async function updateTemplates() {
  try {
    // Get all services
    const servicesResponse = await axios.get(`${apiBaseUrl}/services`, {
      headers: { Authorization: `Bearer ${token}` }
    });
    
    const services = servicesResponse.data.services;
    
    // Update each service
    for (const service of services) {
      console.log(`Updating templates for ${service.id}...`);
      
      try {
        // Get current integration
        const integrationResponse = await axios.get(`${apiBaseUrl}/services/${service.id}/integration`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        
        const integration = integrationResponse.data;
        
        // Update security templates
        const updatedTemplates = integration.templates.map(template => {
          if (template.id === 'dependency-check') {
            return {
              ...template,
              inputs: {
                ...template.inputs,
                severity_threshold: 'HIGH',
                fail_on_severity: 'CRITICAL'
              }
            };
          }
          return template;
        });
        
        // If not using security template, add it
        if (!integration.templates.some(t => t.id === 'dependency-check')) {
          updatedTemplates.push({
            id: 'dependency-check',
            inputs: {
              severity_threshold: 'HIGH',
              fail_on_severity: 'CRITICAL'
            }
          });
        }
        
        // Update integration
        await axios.put(`${apiBaseUrl}/services/${service.id}/integration`, {
          templates: updatedTemplates,
          environments: integration.environments
        }, {
          headers: { Authorization: `Bearer ${token}` }
        });
        
        console.log(`✅ Successfully updated ${service.id}`);
      } catch (error) {
        console.error(`❌ Failed to update ${service.id}: ${error.message}`);
      }
    }
  } catch (error) {
    console.error(`Error: ${error.message}`);
  }
}

updateTemplates();
```

## Appendix

### Template Input Schema

```json
{
  "type": "object",
  "properties": {
    "id": {
      "type": "string",
      "description": "Unique identifier for the template"
    },
    "name": {
      "type": "string",
      "description": "Display name for the template"
    },
    "category": {
      "type": "string",
      "enum": ["build", "test", "security", "quality", "deploy", "verify"],
      "description": "Template category"
    },
    "technology": {
      "type": "string",
      "description": "Technology stack the template applies to"
    },
    "description": {
      "type": "string",
      "description": "Detailed description of the template"
    },
    "content": {
      "type": "string",
      "description": "YAML content of the template"
    },
    "inputs": {
      "type": "object",
      "description": "Input parameters for the template",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "description": {
            "type": "string",
            "description": "Description of the input parameter"
          },
          "type": {
            "type": "string",
            "enum": ["string", "number", "boolean"],
            "description": "Data type of the input parameter"
          },
          "required": {
            "type": "boolean",
            "description": "Whether the input parameter is required"
          },
          "default": {
            "description": "Default value for the input parameter"
          }
        }
      }
    },
    "outputs": {
      "type": "object",
      "description": "Output values from the template",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "description": {
            "type": "string",
            "description": "Description of the output value"
          },
          "type": {
            "type": "string",
            "enum": ["string", "number", "boolean"],
            "description": "Data type of the output value"
          }
        }
      }
    }
  },
  "required": ["id", "name", "category", "content"]
}
```

### Service Integration Schema

```json
{
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Service name"
    },
    "repository": {
      "type": "string",
      "description": "GitHub repository path"
    },
    "type": {
      "type": "string",
      "description": "Service technology type"
    },
    "domain": {
      "type": "string",
      "description": "Service domain"
    },
    "description": {
      "type": "string",
      "description": "Service description"
    },
    "contacts": {
      "type": "array",
      "description": "Contact emails for the service team",
      "items": {
        "type": "string"
      }
    },
    "templates": {
      "type": "array",
      "description": "Templates used by the service",
      "items": {
        "type": "object",
        "properties": {
          "id": {
            "type": "string",
            "description": "Template ID"
          },
          "inputs": {
            "type": "object",
            "description": "Template input values",
            "additionalProperties": true
          }
        },
        "required": ["id"]
      }
    },
    "environments": {
      "type": "object",
      "description": "Environment configurations",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "deployment_strategy": {
            "type": "string",
            "enum": ["rolling-update", "blue-green", "canary"],
            "description": "Deployment strategy"
          },
          "approval_required": {
            "type": "boolean",
            "description": "Whether approval is required for deployment"
          },
          "approvers": {
            "type": "array",
            "description": "List of approver roles",
            "items": {
              "type": "string"
            }
          },
          "auto_deploy": {
            "type": "boolean",
            "description": "Whether to automatically deploy"
          }
        }
      }
    }
  },
  "required": ["name", "repository", "type", "domain"]
}
```

### Related Documentation

- [CI/CD Templates User Guide](https://cicd-docs.exalt-ecommerce.com/templates/user-guide)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Template Development Guide](https://cicd-docs.exalt-ecommerce.com/templates/development)
- [Service Integration Guide](https://cicd-docs.exalt-ecommerce.com/services/integration)
- [API Client Libraries](https://cicd-docs.exalt-ecommerce.com/api/client-libraries)
