#!/bin/bash

# Script to generate Kubernetes deployment configurations for central-configuration services

SERVICES=(
    "ci-cd-templates"
    "database-migrations"
    "deployment-scripts"
    "disaster-recovery"
    "environment-config"
    "infrastructure-as-code"
    "kubernetes-manifests"
    "regional-deployment"
    "secrets-management"
)

# Function to determine service port based on service name
get_service_port() {
    case $1 in
        "ci-cd-templates") echo "8180" ;;
        "database-migrations") echo "8181" ;;
        "deployment-scripts") echo "8182" ;;
        "disaster-recovery") echo "8183" ;;
        "environment-config") echo "8184" ;;
        "infrastructure-as-code") echo "8185" ;;
        "kubernetes-manifests") echo "8186" ;;
        "regional-deployment") echo "8187" ;;
        "secrets-management") echo "8188" ;;
        *) echo "8080" ;;
    esac
}

# Function to create deployment.yaml
create_deployment_yaml() {
    local service=$1
    local service_path=$2
    local port=$(get_service_port $service)
    
    cat > "$service_path/k8s/deployment.yaml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${service}
  namespace: central-configuration
  labels:
    app: ${service}
    component: central-config
    version: v1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${service}
  template:
    metadata:
      labels:
        app: ${service}
        component: central-config
        version: v1
    spec:
      serviceAccountName: ${service}-sa
      containers:
      - name: ${service}
        image: ghcr.io/exalt/${service}:latest
        imagePullPolicy: Always
        ports:
        - containerPort: ${port}
          name: http
          protocol: TCP
        - containerPort: 8081
          name: management
          protocol: TCP
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "kubernetes"
        - name: SERVER_PORT
          value: "${port}"
        - name: MANAGEMENT_SERVER_PORT
          value: "8081"
        - name: CONFIG_SERVER_URL
          value: "http://config-server:8166"
        - name: EUREKA_SERVER_URL
          value: "http://service-registry:8154/eureka"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: ${service}-db-secret
              key: url
        - name: DATABASE_USERNAME
          valueFrom:
            secretKeyRef:
              name: ${service}-db-secret
              key: username
        - name: DATABASE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: ${service}-db-secret
              key: password
        - name: JAVA_OPTS
          value: "-Xms256m -Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=100"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /actuator/health/liveness
            port: management
          initialDelaySeconds: 120
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /actuator/health/readiness
            port: management
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        volumeMounts:
        - name: config
          mountPath: /app/config
        - name: logs
          mountPath: /app/logs
      volumes:
      - name: config
        configMap:
          name: ${service}-config
      - name: logs
        emptyDir: {}
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - ${service}
              topologyKey: kubernetes.io/hostname
---
apiVersion: v1
kind: Service
metadata:
  name: ${service}
  namespace: central-configuration
  labels:
    app: ${service}
    component: central-config
spec:
  type: ClusterIP
  ports:
  - port: ${port}
    targetPort: http
    protocol: TCP
    name: http
  - port: 8081
    targetPort: management
    protocol: TCP
    name: management
  selector:
    app: ${service}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${service}-sa
  namespace: central-configuration
  labels:
    app: ${service}
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${service}-config
  namespace: central-configuration
  labels:
    app: ${service}
data:
  application.yaml: |
    spring:
      application:
        name: ${service}
      cloud:
        kubernetes:
          reload:
            enabled: true
            mode: polling
            period: 5000
    management:
      endpoints:
        web:
          exposure:
            include: health,info,metrics,prometheus
      metrics:
        export:
          prometheus:
            enabled: true
    logging:
      level:
        root: INFO
        com.exalt: DEBUG
---
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ${service}-pdb
  namespace: central-configuration
  labels:
    app: ${service}
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: ${service}
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${service}-hpa
  namespace: central-configuration
  labels:
    app: ${service}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${service}
  minReplicas: 2
  maxReplicas: 10
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
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 50
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
EOF
}

# Function to create service.yaml
create_service_yaml() {
    local service=$1
    local service_path=$2
    local port=$(get_service_port $service)
    
    cat > "$service_path/k8s/service.yaml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: ${service}-external
  namespace: central-configuration
  labels:
    app: ${service}
    component: central-config
    type: external
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
spec:
  type: LoadBalancer
  ports:
  - port: ${port}
    targetPort: http
    protocol: TCP
    name: http
  selector:
    app: ${service}
EOF
}

# Function to create ingress.yaml
create_ingress_yaml() {
    local service=$1
    local service_path=$2
    local port=$(get_service_port $service)
    
    cat > "$service_path/k8s/ingress.yaml" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ${service}
  namespace: central-configuration
  labels:
    app: ${service}
    component: central-config
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "600"
spec:
  tls:
  - hosts:
    - ${service}.central-config.exalt.com
    secretName: ${service}-tls
  rules:
  - host: ${service}.central-config.exalt.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ${service}
            port:
              number: ${port}
EOF
}

# Function to create secrets.yaml template
create_secrets_yaml() {
    local service=$1
    local service_path=$2
    
    cat > "$service_path/k8s/secrets.yaml" << EOF
# This is a template for secrets. In production, use sealed secrets or external secret management
apiVersion: v1
kind: Secret
metadata:
  name: ${service}-db-secret
  namespace: central-configuration
  labels:
    app: ${service}
type: Opaque
stringData:
  url: "jdbc:postgresql://postgres:5432/${service//-/_}_db"
  username: "${service//-/_}_user"
  password: "CHANGE_ME_IN_PRODUCTION"
---
apiVersion: v1
kind: Secret
metadata:
  name: ${service}-app-secret
  namespace: central-configuration
  labels:
    app: ${service}
type: Opaque
stringData:
  jwt-secret: "CHANGE_ME_IN_PRODUCTION"
  api-key: "CHANGE_ME_IN_PRODUCTION"
  encryption-key: "CHANGE_ME_IN_PRODUCTION"
EOF
}

# Main execution
echo "Generating Kubernetes configurations for central-configuration services..."

for service in "${SERVICES[@]}"; do
    echo "Processing ${service}..."
    service_path="/mnt/c/Users/frich/Desktop/Exalt-Application-Limited/Exalt-Application-Limited/social-ecommerce-ecosystem/central-configuration/${service}"
    
    if [ -d "${service_path}/k8s" ]; then
        create_deployment_yaml "${service}" "${service_path}"
        create_service_yaml "${service}" "${service_path}"
        create_ingress_yaml "${service}" "${service_path}"
        create_secrets_yaml "${service}" "${service_path}"
        echo "✅ Generated Kubernetes configs for ${service}"
    else
        echo "❌ k8s directory not found for ${service}"
    fi
done

echo "Kubernetes configuration generation complete!"