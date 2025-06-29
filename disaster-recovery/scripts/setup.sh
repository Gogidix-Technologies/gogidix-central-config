#!/bin/bash

# Setup script for disaster-recovery
# This script sets up the development environment for the service

set -e

echo "Setting up disaster-recovery development environment..."

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
mkdir -p src/main/java/com/exalt/centralconfig/disaster-recovery_CLEAN
mkdir -p src/main/resources
mkdir -p src/test/java/com/exalt/centralconfig/disaster-recovery_CLEAN
mkdir -p src/test/resources
mkdir -p database/migrations
mkdir -p database/seeds
mkdir -p logs

# Set up environment variables
echo "Setting up environment variables..."
cat > .env.local << 'ENV_EOF'
# Local development environment variables
disaster-recovery=disaster-recovery
SERVICE_PORT=8080
SPRING_PROFILES_ACTIVE=local
DATABASE_URL=jdbc:postgresql://localhost:5432/disaster-recovery_db
DATABASE_USERNAME=disaster-recovery_user
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
    docker exec -i $(docker-compose ps -q postgres) psql -U disaster-recovery_user -d disaster-recovery_db < database/migrations/init.sql
fi

# Build the service
echo "Building disaster-recovery..."
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
