import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const manifestCreationTimes = new Trend('manifest_creation_times');
const manifestValidationTimes = new Trend('manifest_validation_times');
const templateRenderingTimes = new Trend('template_rendering_times');
const failedValidations = new Counter('failed_validations');
const failedRenderings = new Counter('failed_renderings');

// Test configuration
export const options = {
  scenarios: {
    // API endpoint testing
    api_endpoints: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 10 },  // Ramp up
        { duration: '40s', target: 20 },  // Increase load
        { duration: '1m', target: 20 },   // Maintain load
        { duration: '20s', target: 0 },   // Ramp down
      ],
    },
    
    // Manifest validation operations
    validation_operations: {
      executor: 'constant-arrival-rate',
      rate: 60,                          // 60 iterations per timeUnit
      timeUnit: '1m',                    // 60 iterations per minute
      duration: '2m',                    // Run for 2 minutes
      preAllocatedVUs: 10,               // Allocate 10 VUs initially
      maxVUs: 30,                        // Maximum 30 VUs
      startTime: '30s',                  // Start after the API endpoint scenario has begun
    },
    
    // Template rendering operations
    template_operations: {
      executor: 'per-vu-iterations',
      vus: 8,                            // 8 concurrent users
      iterations: 12,                    // Each user performs 12 operations
      maxDuration: '3m',                 // Maximum duration of 3 minutes
      startTime: '1m30s',                // Start after other scenarios have begun
    }
  },
  
  thresholds: {
    http_req_duration: ['p(95)<1200'],   // 95% of requests complete within 1.2s
    http_req_failed: ['rate<0.02'],      // Less than 2% of requests should fail
    'manifest_creation_times': ['p(95)<800'],   // 95% of manifest creations under 800ms
    'manifest_validation_times': ['p(95)<300'], // 95% of validations under 300ms
    'template_rendering_times': ['p(95)<600'],  // 95% of template renderings under 600ms
  },
};

// Helper for basic auth
const getAuthHeaders = () => ({
  'Authorization': `Basic ${__ENV.AUTH || 'YWRtaW46YWRtaW4='}`, // admin:admin in base64
  'Accept': 'application/json',
  'Content-Type': 'application/json',
});

// API endpoint check function
export function checkEndpoints() {
  // Check health endpoint
  const healthRes = http.get(`${__ENV.BASE_URL || 'http://localhost:8080'}/actuator/health`);
  check(healthRes, {
    'health endpoint returns 200': (r) => r.status === 200,
    'health endpoint reports UP': (r) => r.json('status') === 'UP',
  });
  
  // Check manifest list endpoint
  const listRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests?limit=10`, 
    { headers: getAuthHeaders() }
  );
  
  check(listRes, {
    'list manifests returns 200': (r) => r.status === 200,
    'list manifests returns array': (r) => Array.isArray(r.json()),
  });
  
  sleep(Math.random() * 1 + 0.5);
}

// Manifest validation testing function
export function testManifestValidation() {
  // Generate test manifest for validation
  const testManifest = generateRandomManifest();
  
  // Create request payload
  const data = JSON.stringify({
    content: testManifest
  });
  
  // Test validation
  const startTime = new Date().getTime();
  const validationRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/validate`,
    data,
    { headers: getAuthHeaders() }
  );
  const endTime = new Date().getTime();
  manifestValidationTimes.add(endTime - startTime);
  
  // Check validation result
  const validationPassed = check(validationRes, {
    'validate returns 200': (r) => r.status === 200,
    'validation result is returned': (r) => r.json('valid') !== undefined,
  });
  
  if (!validationPassed) {
    failedValidations.add(1);
  }
  
  sleep(Math.random() * 0.5 + 0.2);
}

// Template rendering operations
export function testTemplateRendering() {
  // Create unique identifiers for this test run
  const testId = Math.random().toString(36).substring(2, 10);
  
  // 1. Create a template
  const templateData = JSON.stringify({
    name: `perf-template-${testId}`,
    description: `Performance test template ${testId}`,
    content: getDeploymentTemplate()
  });
  
  const templateRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/templates`,
    templateData,
    { headers: getAuthHeaders() }
  );
  
  const templateCreated = check(templateRes, {
    'template creation returns 201': (r) => r.status === 201,
    'template has id': (r) => r.json('id') !== undefined,
  });
  
  if (!templateCreated) {
    failedRenderings.add(1);
    sleep(1);
    return;
  }
  
  const templateId = templateRes.json('id');
  
  // 2. Use template to render a manifest
  const parameters = {
    NAME: `service-${testId}`,
    NAMESPACE: ['default', 'dev', 'prod', 'staging'][Math.floor(Math.random() * 4)],
    REPLICAS: Math.floor(Math.random() * 5) + 1,
    IMAGE: `exalt/microservice-${testId}:latest`,
    PORT: 8000 + Math.floor(Math.random() * 1000)
  };
  
  const renderData = JSON.stringify({
    templateId: templateId,
    parameters: parameters
  });
  
  const startTime = new Date().getTime();
  const renderRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/from-template`,
    renderData,
    { headers: getAuthHeaders() }
  );
  const endTime = new Date().getTime();
  
  templateRenderingTimes.add(endTime - startTime);
  
  const renderingPassed = check(renderRes, {
    'rendering returns 201': (r) => r.status === 201 || r.status === 200,
    'rendered manifest has id': (r) => r.json('id') !== undefined,
    'rendered manifest has correct name': (r) => r.json('name') === parameters.NAME,
  });
  
  if (!renderingPassed) {
    failedRenderings.add(1);
  }
  
  // Optional: Clean up the created template and manifest
  if (templateCreated && renderingPassed) {
    const manifestId = renderRes.json('id');
    http.del(
      `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/${manifestId}`,
      null,
      { headers: getAuthHeaders() }
    );
    
    http.del(
      `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/templates/${templateId}`,
      null,
      { headers: getAuthHeaders() }
    );
  }
  
  sleep(Math.random() * 1 + 0.5);
}

// Create and store manifest test
export function testManifestCreation() {
  // Generate a random manifest
  const testId = Math.random().toString(36).substring(2, 10);
  const name = `service-${testId}`;
  const namespace = ['default', 'dev', 'prod', 'staging'][Math.floor(Math.random() * 4)];
  
  const manifestData = JSON.stringify({
    kind: "Deployment",
    name: name,
    namespace: namespace,
    content: getTestDeploymentYaml(name, namespace)
  });
  
  // Measure creation time
  const startTime = new Date().getTime();
  const createRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests`,
    manifestData,
    { headers: getAuthHeaders() }
  );
  const endTime = new Date().getTime();
  
  manifestCreationTimes.add(endTime - startTime);
  
  const creationPassed = check(createRes, {
    'manifest creation returns 201': (r) => r.status === 201,
    'created manifest has id': (r) => r.json('id') !== undefined,
  });
  
  // Clean up the created manifest
  if (creationPassed) {
    const manifestId = createRes.json('id');
    http.del(
      `${__ENV.BASE_URL || 'http://localhost:8080'}/api/manifests/${manifestId}`,
      null,
      { headers: getAuthHeaders() }
    );
  }
  
  sleep(Math.random() * 0.5 + 0.5);
}

// Main function
export default function() {
  // Select function based on scenario
  const scenario = __ENV.SCENARIO;
  
  switch(scenario) {
    case 'validation_operations':
      testManifestValidation();
      break;
      
    case 'template_operations':
      testTemplateRendering();
      break;
      
    case 'manifest_creation':
      testManifestCreation();
      break;
      
    default:
      // Default to basic API endpoint testing
      checkEndpoints();
  }
}

// Helper functions

function generateRandomManifest() {
  const testId = Math.random().toString(36).substring(2, 10);
  const name = `test-service-${testId}`;
  const namespace = ['default', 'dev', 'prod', 'staging'][Math.floor(Math.random() * 4)];
  const replicas = Math.floor(Math.random() * 5) + 1;
  
  return getTestDeploymentYaml(name, namespace, replicas);
}

function getTestDeploymentYaml(name, namespace, replicas = 1) {
  return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${name}
  namespace: ${namespace}
spec:
  replicas: ${replicas}
  selector:
    matchLabels:
      app: ${name}
  template:
    metadata:
      labels:
        app: ${name}
    spec:
      containers:
      - name: ${name}-container
        image: nginx:latest
        ports:
        - containerPort: 80`;
}

function getDeploymentTemplate() {
  return `apiVersion: apps/v1
kind: Deployment
metadata:
  name: \${NAME}
  namespace: \${NAMESPACE}
spec:
  replicas: \${REPLICAS}
  selector:
    matchLabels:
      app: \${NAME}
  template:
    metadata:
      labels:
        app: \${NAME}
    spec:
      containers:
      - name: \${NAME}
        image: \${IMAGE}
        ports:
        - containerPort: \${PORT}`;
}
