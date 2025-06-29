#!/bin/bash

# Script to generate setup.sh and dev.sh for all central-configuration services

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

# Function to create setup.sh
create_setup_sh() {
    local service=$1
    local service_path=$2
    cat > "$service_path/scripts/setup.sh" << 'EOF'
#!/bin/bash

# Setup script for SERVICE_NAME
# This script sets up the development environment for the service

set -e

echo "Setting up SERVICE_NAME development environment..."

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | awk -F. '{print $1}')
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo "Error: Java 17 or higher is required. Current version is $JAVA_VERSION"
    exit 1
fi

# Check Maven installation
if ! command -v mvn &> /dev/null; then
    echo "Error: Maven is not installed. Please install Maven 3.8.6 or higher"
    exit 1
fi

# Check Docker installation
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker"
    exit 1
fi

# Check Docker Compose installation
if ! command -v docker-compose &> /dev/null; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose"
    exit 1
fi

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p src/main/java/com/exalt/centralconfig/SERVICE_NAME_CLEAN
mkdir -p src/main/resources
mkdir -p src/test/java/com/exalt/centralconfig/SERVICE_NAME_CLEAN
mkdir -p src/test/resources
mkdir -p database/migrations
mkdir -p database/seeds
mkdir -p logs

# Set up environment variables
echo "Setting up environment variables..."
cat > .env.local << 'ENV_EOF'
# Local development environment variables
SERVICE_NAME=SERVICE_NAME
SERVICE_PORT=8080
SPRING_PROFILES_ACTIVE=local
DATABASE_URL=jdbc:postgresql://localhost:5432/SERVICE_NAME_db
DATABASE_USERNAME=SERVICE_NAME_user
DATABASE_PASSWORD=changeme
REDIS_HOST=localhost
REDIS_PORT=6379
KAFKA_BOOTSTRAP_SERVERS=localhost:9092
CONFIG_SERVER_URL=http://localhost:8166
EUREKA_SERVER_URL=http://localhost:8154/eureka
LOG_LEVEL=DEBUG
ENV_EOF

# Install Maven dependencies
echo "Installing Maven dependencies..."
mvn clean install -DskipTests

# Pull required Docker images
echo "Pulling required Docker images..."
docker pull postgres:14-alpine
docker pull redis:7-alpine
docker pull confluentinc/cp-kafka:latest

# Create Docker network
echo "Creating Docker network..."
docker network create central-config-network 2>/dev/null || true

# Start infrastructure services
echo "Starting infrastructure services..."
docker-compose -f docker-compose.yml up -d postgres redis kafka

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 10

# Run database migrations
echo "Running database migrations..."
if [ -f "database/migrations/init.sql" ]; then
    docker exec -i $(docker-compose ps -q postgres) psql -U SERVICE_NAME_user -d SERVICE_NAME_db < database/migrations/init.sql
fi

# Build the service
echo "Building SERVICE_NAME..."
mvn clean package

echo "Setup complete! You can now run the service using ./scripts/dev.sh"
echo ""
echo "Available commands:"
echo "  ./scripts/dev.sh start    - Start the service"
echo "  ./scripts/dev.sh stop     - Stop the service"
echo "  ./scripts/dev.sh restart  - Restart the service"
echo "  ./scripts/dev.sh logs     - View service logs"
echo "  ./scripts/dev.sh test     - Run tests"
echo "  ./scripts/dev.sh clean    - Clean build artifacts"
EOF
    
    # Replace SERVICE_NAME with actual service name
    sed -i "s/SERVICE_NAME/${service}/g" "$service_path/scripts/setup.sh"
    
    # Replace SERVICE_NAME_CLEAN with cleaned service name (replace - with _)
    local clean_name=$(echo "$service" | tr '-' '_')
    sed -i "s/SERVICE_NAME_CLEAN/${clean_name}/g" "$service_path/scripts/setup.sh"
    
    chmod +x "$service_path/scripts/setup.sh"
}

# Function to create dev.sh
create_dev_sh() {
    local service=$1
    local service_path=$2
    cat > "$service_path/scripts/dev.sh" << 'EOF'
#!/bin/bash

# Development utility script for SERVICE_NAME
# This script provides common development commands

set -e

SERVICE_NAME="SERVICE_NAME"
SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load environment variables
if [ -f "$SERVICE_DIR/.env.local" ]; then
    export $(cat "$SERVICE_DIR/.env.local" | grep -v '^#' | xargs)
fi

# Function to start the service
start_service() {
    echo "Starting $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    
    # Start infrastructure if not running
    docker-compose up -d
    
    # Wait for dependencies
    sleep 5
    
    # Start the application
    nohup java -jar target/${SERVICE_NAME}-*.jar > logs/app.log 2>&1 &
    echo $! > .pid
    
    echo "$SERVICE_NAME started with PID $(cat .pid)"
    echo "Logs available at: logs/app.log"
}

# Function to stop the service
stop_service() {
    echo "Stopping $SERVICE_NAME..."
    
    if [ -f .pid ]; then
        PID=$(cat .pid)
        if ps -p $PID > /dev/null; then
            kill $PID
            echo "$SERVICE_NAME stopped"
        else
            echo "$SERVICE_NAME is not running"
        fi
        rm -f .pid
    else
        echo "PID file not found. $SERVICE_NAME may not be running"
    fi
    
    # Optionally stop infrastructure
    read -p "Stop infrastructure services? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker-compose down
    fi
}

# Function to restart the service
restart_service() {
    stop_service
    sleep 2
    start_service
}

# Function to view logs
view_logs() {
    if [ -f logs/app.log ]; then
        tail -f logs/app.log
    else
        echo "No logs found. Is the service running?"
    fi
}

# Function to run tests
run_tests() {
    echo "Running tests for $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    
    # Unit tests
    echo "Running unit tests..."
    mvn test -Dtest="**/unit/**"
    
    # Integration tests
    echo "Running integration tests..."
    docker-compose up -d
    sleep 5
    mvn test -Dtest="**/integration/**"
    
    # E2E tests
    echo "Running E2E tests..."
    mvn test -Dtest="**/e2e/**"
    
    echo "All tests completed!"
}

# Function to clean build artifacts
clean_build() {
    echo "Cleaning build artifacts..."
    cd "$SERVICE_DIR"
    mvn clean
    rm -rf logs/*
    rm -f .pid
    docker-compose down -v
    echo "Clean complete!"
}

# Function to build the service
build_service() {
    echo "Building $SERVICE_NAME..."
    cd "$SERVICE_DIR"
    mvn clean package -DskipTests
    echo "Build complete!"
}

# Function to run development mode with hot reload
dev_mode() {
    echo "Starting $SERVICE_NAME in development mode..."
    cd "$SERVICE_DIR"
    docker-compose up -d
    mvn spring-boot:run -Dspring-boot.run.profiles=local
}

# Function to check service health
health_check() {
    echo "Checking $SERVICE_NAME health..."
    curl -s http://localhost:${SERVICE_PORT:-8080}/actuator/health | jq '.' || echo "Service is not responding"
}

# Function to view service info
service_info() {
    echo "Service Information:"
    echo "==================="
    echo "Name: $SERVICE_NAME"
    echo "Directory: $SERVICE_DIR"
    echo "Port: ${SERVICE_PORT:-8080}"
    echo "Profile: ${SPRING_PROFILES_ACTIVE:-default}"
    echo ""
    
    if [ -f .pid ] && ps -p $(cat .pid) > /dev/null 2>&1; then
        echo "Status: Running (PID: $(cat .pid))"
    else
        echo "Status: Stopped"
    fi
    
    echo ""
    echo "Infrastructure Services:"
    docker-compose ps
}

# Main command handler
case "$1" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    restart)
        restart_service
        ;;
    logs)
        view_logs
        ;;
    test)
        run_tests
        ;;
    clean)
        clean_build
        ;;
    build)
        build_service
        ;;
    dev)
        dev_mode
        ;;
    health)
        health_check
        ;;
    info)
        service_info
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|logs|test|clean|build|dev|health|info}"
        echo ""
        echo "Commands:"
        echo "  start    - Start the service"
        echo "  stop     - Stop the service"
        echo "  restart  - Restart the service"
        echo "  logs     - View service logs"
        echo "  test     - Run all tests"
        echo "  clean    - Clean build artifacts"
        echo "  build    - Build the service"
        echo "  dev      - Run in development mode with hot reload"
        echo "  health   - Check service health"
        echo "  info     - Display service information"
        exit 1
        ;;
esac
EOF
    
    # Replace SERVICE_NAME with actual service name
    sed -i "s/SERVICE_NAME/${service}/g" "$service_path/scripts/dev.sh"
    
    chmod +x "$service_path/scripts/dev.sh"
}

# Main execution
echo "Generating setup and dev scripts for all central-configuration services..."

for service in "${SERVICES[@]}"; do
    echo "Processing ${service}..."
    service_path="/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}"
    
    if [ -d "${service_path}/scripts" ]; then
        create_setup_sh "${service}" "${service_path}"
        create_dev_sh "${service}" "${service_path}"
        echo "✅ Generated scripts for ${service}"
    else
        echo "❌ Scripts directory not found for ${service}"
    fi
done

echo "Script generation complete!"