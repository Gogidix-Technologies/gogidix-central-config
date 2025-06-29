#!/bin/bash

# Script to generate CI/CD workflow files for all central-configuration services

SERVICES=(
    "ci-cd-templates"
    "config-server"
    "database-migrations"
    "deployment-scripts"
    "disaster-recovery"
    "environment-config"
    "infrastructure-as-code"
    "kubernetes-manifests"
    "regional-deployment"
    "secrets-management"
)

# Function to create build.yml
create_build_yml() {
    local service=$1
    local service_path=$2
    cat > "$service_path/.github/workflows/build.yml" << EOF
name: Build ${service} Service

on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]

env:
  JAVA_VERSION: '17'
  MAVEN_VERSION: '3.8.6'
  SERVICE_NAME: ${service}
  DOCKER_REGISTRY: ghcr.io
  DOCKER_IMAGE: ghcr.io/\${{ github.repository_owner }}/${service}

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: \${{ runner.os }}-m2-\${{ hashFiles('**/pom.xml') }}
        restore-keys: \${{ runner.os }}-m2
        
    - name: Build with Maven
      run: mvn clean compile
      working-directory: central-configuration/${service}
      
    - name: Package application
      run: mvn package -DskipTests
      working-directory: central-configuration/${service}
      
    - name: Build Docker image
      run: |
        docker build -t \${{ env.DOCKER_IMAGE }}:\${{ github.sha }} .
        docker tag \${{ env.DOCKER_IMAGE }}:\${{ github.sha }} \${{ env.DOCKER_IMAGE }}:latest
      working-directory: central-configuration/${service}
        
    - name: Log in to Docker Registry
      if: github.event_name != 'pull_request'
      uses: docker/login-action@v2
      with:
        registry: \${{ env.DOCKER_REGISTRY }}
        username: \${{ github.actor }}
        password: \${{ secrets.GITHUB_TOKEN }}
        
    - name: Push Docker image
      if: github.event_name != 'pull_request'
      run: |
        docker push \${{ env.DOCKER_IMAGE }}:\${{ github.sha }}
        docker push \${{ env.DOCKER_IMAGE }}:latest
        
    - name: Upload build artifacts
      uses: actions/upload-artifact@v3
      with:
        name: build-artifacts
        path: central-configuration/${service}/target/
        retention-days: 7
EOF
}

# Function to create test.yml
create_test_yml() {
    local service=$1
    local service_path=$2
    cat > "$service_path/.github/workflows/test.yml" << EOF
name: Test ${service} Service

on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]

env:
  JAVA_VERSION: '17'
  MAVEN_VERSION: '3.8.6'
  SERVICE_NAME: ${service}

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: \${{ runner.os }}-m2-\${{ hashFiles('**/pom.xml') }}
        restore-keys: \${{ runner.os }}-m2
        
    - name: Run unit tests
      run: mvn test -Dtest="**/unit/**"
      working-directory: central-configuration/${service}
      
    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Unit Test Results
        path: central-configuration/${service}/target/surefire-reports/*.xml
        reporter: java-junit
        
  integration-tests:
    runs-on: ubuntu-latest
    needs: unit-tests
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Start dependencies
      run: docker-compose up -d
      working-directory: central-configuration/${service}
      
    - name: Run integration tests
      run: mvn test -Dtest="**/integration/**"
      working-directory: central-configuration/${service}
      
    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: Integration Test Results
        path: central-configuration/${service}/target/surefire-reports/*.xml
        reporter: java-junit
        
    - name: Stop dependencies
      if: always()
      run: docker-compose down
      working-directory: central-configuration/${service}
      
  e2e-tests:
    runs-on: ubuntu-latest
    needs: integration-tests
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Build application
      run: mvn package -DskipTests
      working-directory: central-configuration/${service}
      
    - name: Start application
      run: |
        docker-compose up -d
        sleep 30
      working-directory: central-configuration/${service}
      
    - name: Run E2E tests
      run: mvn test -Dtest="**/e2e/**"
      working-directory: central-configuration/${service}
      
    - name: Generate test report
      uses: dorny/test-reporter@v1
      if: success() || failure()
      with:
        name: E2E Test Results
        path: central-configuration/${service}/target/surefire-reports/*.xml
        reporter: java-junit
        
    - name: Stop application
      if: always()
      run: docker-compose down
      working-directory: central-configuration/${service}
      
  performance-tests:
    runs-on: ubuntu-latest
    needs: e2e-tests
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        
    - name: Install k6
      run: |
        sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
        echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
        sudo apt-get update
        sudo apt-get install k6
        
    - name: Build and start application
      run: |
        mvn package -DskipTests
        docker-compose up -d
        sleep 30
      working-directory: central-configuration/${service}
      
    - name: Run performance tests
      run: k6 run tests/performance/*.js
      working-directory: central-configuration/${service}
      
    - name: Upload performance results
      uses: actions/upload-artifact@v3
      with:
        name: performance-results
        path: central-configuration/${service}/performance-results/
        retention-days: 30
        
    - name: Stop application
      if: always()
      run: docker-compose down
      working-directory: central-configuration/${service}
EOF
}

# Function to create code-quality.yml
create_code_quality_yml() {
    local service=$1
    local service_path=$2
    cat > "$service_path/.github/workflows/code-quality.yml" << EOF
name: Code Quality Check - ${service}

on:
  push:
    branches: [ main, develop, feature/* ]
  pull_request:
    branches: [ main, develop ]

env:
  JAVA_VERSION: '17'
  SERVICE_NAME: ${service}

jobs:
  code-quality:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      with:
        fetch-depth: 0
        
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Cache SonarCloud packages
      uses: actions/cache@v3
      with:
        path: ~/.sonar/cache
        key: \${{ runner.os }}-sonar
        restore-keys: \${{ runner.os }}-sonar
        
    - name: Cache Maven dependencies
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: \${{ runner.os }}-m2-\${{ hashFiles('**/pom.xml') }}
        restore-keys: \${{ runner.os }}-m2
        
    - name: Run SpotBugs
      run: mvn spotbugs:check
      working-directory: central-configuration/${service}
      
    - name: Run Checkstyle
      run: mvn checkstyle:check
      working-directory: central-configuration/${service}
      
    - name: Run PMD
      run: mvn pmd:check
      working-directory: central-configuration/${service}
      
    - name: Analyze with SonarCloud
      env:
        GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: \${{ secrets.SONAR_TOKEN }}
      run: mvn verify sonar:sonar -Dsonar.projectKey=exalt_${service}
      working-directory: central-configuration/${service}
      
    - name: Check code coverage
      run: |
        mvn jacoco:report
        echo "Code coverage report generated"
      working-directory: central-configuration/${service}
      
    - name: Upload code coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: central-configuration/${service}/target/site/jacoco/jacoco.xml
        flags: unittests
        name: codecov-${service}
        
    - name: Comment PR with quality metrics
      uses: actions/github-script@v6
      if: github.event_name == 'pull_request'
      with:
        script: |
          const fs = require('fs');
          const coverage = 'Check the build logs for detailed code quality metrics';
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: '## Code Quality Report\\n' + coverage
          });
EOF
}

# Function to create security-scan.yml
create_security_scan_yml() {
    local service=$1
    local service_path=$2
    cat > "$service_path/.github/workflows/security-scan.yml" << EOF
name: Security Scan - ${service}

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]
  schedule:
    - cron: '0 0 * * 0'  # Weekly scan on Sundays

env:
  JAVA_VERSION: '17'
  SERVICE_NAME: ${service}

jobs:
  dependency-check:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Run OWASP Dependency Check
      run: mvn org.owasp:dependency-check-maven:check
      working-directory: central-configuration/${service}
      
    - name: Upload dependency check results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: dependency-check-report
        path: central-configuration/${service}/target/dependency-check-report.html
        
  container-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Build Docker image
      run: docker build -t ${service}:scan .
      working-directory: central-configuration/${service}
      
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: '${service}:scan'
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH,MEDIUM'
        
    - name: Upload Trivy scan results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'
        
  code-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Initialize CodeQL
      uses: github/codeql-action/init@v2
      with:
        languages: java
        
    - name: Set up JDK \${{ env.JAVA_VERSION }}
      uses: actions/setup-java@v3
      with:
        java-version: \${{ env.JAVA_VERSION }}
        distribution: 'temurin'
        
    - name: Build project
      run: mvn clean compile
      working-directory: central-configuration/${service}
      
    - name: Perform CodeQL Analysis
      uses: github/codeql-action/analyze@v2
      
  secrets-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Run GitLeaks
      uses: gitleaks/gitleaks-action@v2
      env:
        GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
        
  license-scan:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: FOSSA Scan
      uses: fossas/fossa-action@main
      with:
        api-key: \${{ secrets.FOSSA_API_KEY }}
        
  security-report:
    runs-on: ubuntu-latest
    needs: [dependency-check, container-scan, code-scan, secrets-scan, license-scan]
    if: always()
    
    steps:
    - name: Generate security report summary
      run: |
        echo "Security scan completed. Check individual job results for details."
        echo "- Dependency vulnerabilities: Check OWASP report"
        echo "- Container vulnerabilities: Check Trivy results"
        echo "- Code vulnerabilities: Check CodeQL results"
        echo "- Secrets detection: Check GitLeaks results"
        echo "- License compliance: Check FOSSA results"
EOF
}

# Function to create deploy-development.yml
create_deploy_development_yml() {
    local service=$1
    local service_path=$2
    cat > "$service_path/.github/workflows/deploy-development.yml" << EOF
name: Deploy to Development - ${service}

on:
  push:
    branches: [ develop ]
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to deploy (leave empty for latest)'
        required: false
        default: 'latest'

env:
  JAVA_VERSION: '17'
  SERVICE_NAME: ${service}
  DOCKER_REGISTRY: ghcr.io
  DOCKER_IMAGE: ghcr.io/\${{ github.repository_owner }}/${service}
  KUBE_NAMESPACE: central-config-dev
  DEPLOYMENT_NAME: ${service}-deployment

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: development
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: \${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: \${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: \${{ secrets.AWS_DEFAULT_REGION }}
        
    - name: Configure kubectl
      uses: aws-actions/amazon-eks-update-kubeconfig@v1
      with:
        cluster-name: \${{ secrets.EKS_CLUSTER_NAME }}
        
    - name: Determine deployment version
      id: version
      run: |
        if [ "${{ github.event.inputs.version }}" == "latest" ] || [ -z "${{ github.event.inputs.version }}" ]; then
          echo "version=\${{ github.sha }}" >> \$GITHUB_OUTPUT
        else
          echo "version=\${{ github.event.inputs.version }}" >> \$GITHUB_OUTPUT
        fi
        
    - name: Update Kubernetes deployment
      run: |
        kubectl set image deployment/\${{ env.DEPLOYMENT_NAME }} \\
          ${service}=\${{ env.DOCKER_IMAGE }}:\${{ steps.version.outputs.version }} \\
          -n \${{ env.KUBE_NAMESPACE }}
          
    - name: Wait for rollout to complete
      run: |
        kubectl rollout status deployment/\${{ env.DEPLOYMENT_NAME }} \\
          -n \${{ env.KUBE_NAMESPACE }} \\
          --timeout=600s
          
    - name: Verify deployment
      run: |
        kubectl get pods -l app=${service} -n \${{ env.KUBE_NAMESPACE }}
        kubectl get services -l app=${service} -n \${{ env.KUBE_NAMESPACE }}
        
    - name: Run smoke tests
      run: |
        SERVICE_URL=\$(kubectl get service ${service}-service -n \${{ env.KUBE_NAMESPACE }} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
        echo "Service URL: \$SERVICE_URL"
        
        # Basic health check
        curl -f -s -o /dev/null -w "%{http_code}" http://\$SERVICE_URL/actuator/health || exit 1
        
    - name: Update deployment tracking
      uses: actions/github-script@v6
      with:
        script: |
          const deployment = await github.rest.repos.createDeployment({
            owner: context.repo.owner,
            repo: context.repo.repo,
            ref: context.sha,
            task: 'deploy',
            auto_merge: false,
            required_contexts: [],
            environment: 'development',
            description: 'Deployment to development environment'
          });
          
          await github.rest.repos.createDeploymentStatus({
            owner: context.repo.owner,
            repo: context.repo.repo,
            deployment_id: deployment.data.id,
            state: 'success',
            target_url: \`https://\${process.env.SERVICE_URL}\`,
            description: 'Deployment completed successfully'
          });
          
    - name: Send notification
      if: always()
      uses: 8398a7/action-slack@v3
      with:
        status: \${{ job.status }}
        text: |
          Deployment \${{ job.status }} for ${service}
          Version: \${{ steps.version.outputs.version }}
          Environment: Development
          Actor: \${{ github.actor }}
        webhook_url: \${{ secrets.SLACK_WEBHOOK }}
EOF
}

# Main execution
echo "Generating CI/CD workflows for all central-configuration services..."

for service in "${SERVICES[@]}"; do
    echo "Processing ${service}..."
    service_path="/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}"
    
    if [ -d "${service_path}/.github/workflows" ]; then
        create_build_yml "${service}" "${service_path}"
        create_test_yml "${service}" "${service_path}"
        create_code_quality_yml "${service}" "${service_path}"
        create_security_scan_yml "${service}" "${service_path}"
        create_deploy_development_yml "${service}" "${service_path}"
        echo "✅ Generated workflows for ${service}"
    else
        echo "❌ Workflow directory not found for ${service}"
    fi
done

echo "CI/CD workflow generation complete!"