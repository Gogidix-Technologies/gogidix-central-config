#!/bin/bash

# Development utility script for regional-deployment
# This script provides common development commands

set -e

regional-deployment="regional-deployment"
SERVICE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Load environment variables
if [ -f "$SERVICE_DIR/.env.local" ]; then
    export $(cat "$SERVICE_DIR/.env.local" | grep -v '^#' | xargs)
fi

# Function to start the service
start_service() {
    echo "Starting $regional-deployment..."
    cd "$SERVICE_DIR"
    
    # Start infrastructure if not running
    docker-compose up -d
    
    # Wait for dependencies
    sleep 5
    
    # Start the application
    nohup java -jar target/${regional-deployment}-*.jar > logs/app.log 2>&1 &
    echo $! > .pid
    
    echo "$regional-deployment started with PID $(cat .pid)"
    echo "Logs available at: logs/app.log"
}

# Function to stop the service
stop_service() {
    echo "Stopping $regional-deployment..."
    
    if [ -f .pid ]; then
        PID=$(cat .pid)
        if ps -p $PID > /dev/null; then
            kill $PID
            echo "$regional-deployment stopped"
        else
            echo "$regional-deployment is not running"
        fi
        rm -f .pid
    else
        echo "PID file not found. $regional-deployment may not be running"
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
    echo "Running tests for $regional-deployment..."
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
    echo "Building $regional-deployment..."
    cd "$SERVICE_DIR"
    mvn clean package -DskipTests
    echo "Build complete!"
}

# Function to run development mode with hot reload
dev_mode() {
    echo "Starting $regional-deployment in development mode..."
    cd "$SERVICE_DIR"
    docker-compose up -d
    mvn spring-boot:run -Dspring-boot.run.profiles=local
}

# Function to check service health
health_check() {
    echo "Checking $regional-deployment health..."
    curl -s http://localhost:${SERVICE_PORT:-8080}/actuator/health | jq '.' || echo "Service is not responding"
}

# Function to view service info
service_info() {
    echo "Service Information:"
    echo "==================="
    echo "Name: $regional-deployment"
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
