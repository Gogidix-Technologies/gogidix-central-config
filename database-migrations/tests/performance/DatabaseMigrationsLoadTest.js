import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Create custom metrics
const migrationExecutionTimes = new Trend('migration_execution_times');
const successfulMigrations = new Counter('successful_migrations');
const failedMigrations = new Counter('failed_migrations');

// Test configuration
export const options = {
  // Define test scenarios
  scenarios: {
    // Heavy concurrent API access
    api_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 20 },  // Ramp up to 20 users over 30s
        { duration: '1m', target: 20 },   // Stay at 20 users for 1 minute
        { duration: '30s', target: 0 },   // Ramp down to 0 users
      ],
      gracefulRampDown: '10s',
    },
    
    // Migration execution performance (fewer users, realistic for admin operations)
    migration_execution: {
      executor: 'constant-vus',
      vus: 5,
      duration: '1m',
      startTime: '2m',  // Start after the api_load scenario
    }
  },
  
  // Define thresholds
  thresholds: {
    http_req_duration: ['p(95)<1000'], // 95% of requests should complete within 1s
    'http_req_duration{scenario:api_load}': ['p(95)<500'], // API requests should be faster
    'http_req_duration{scenario:migration_execution}': ['p(95)<5000'], // Migrations can take longer
    http_req_failed: ['rate<0.01'], // Less than 1% of requests should fail
    'migration_execution_times': ['p(95)<3000'], // Migration execution should be under 3s for p95
  },
};

// Base URL
const baseUrl = 'http://localhost:8080';

// Helper for basic auth
const getAuthHeaders = () => {
  const credentials = `admin:admin`; // Replace with your test credentials
  return {
    'Authorization': `Basic ${encoding.b64encode(credentials)}`,
    'Content-Type': 'application/json',
  };
};

// Test for API status endpoints
export function apiStatus() {
  // Health check
  const healthRes = http.get(`${baseUrl}/actuator/health`);
  check(healthRes, {
    'health check status is 200': (r) => r.status === 200,
    'health check indicates up': (r) => r.json('status') === 'UP',
  });
  
  // Migration status
  const statusRes = http.get(`${baseUrl}/api/migrations/status`, { headers: getAuthHeaders() });
  check(statusRes, {
    'migration status code is 200': (r) => r.status === 200,
    'migration status contains data': (r) => r.json('appliedMigrations') !== undefined,
  });
  
  sleep(1);
}

// Test for migration validation
export function validateMigrations() {
  const validateRes = http.get(`${baseUrl}/api/migrations/validate`, { headers: getAuthHeaders() });
  check(validateRes, {
    'validation status is 200': (r) => r.status === 200,
    'validation returns results': (r) => r.json('valid') !== undefined,
  });
  
  sleep(1);
}

// Test for migration execution (most resource-intensive)
export function executeMigration() {
  const startTime = new Date().getTime();
  
  const executeRes = http.post(`${baseUrl}/api/migrations/execute`, null, { headers: getAuthHeaders() });
  
  const endTime = new Date().getTime();
  migrationExecutionTimes.add(endTime - startTime);
  
  check(executeRes, {
    'migration execution status is 200': (r) => r.status === 200,
    'migration execution is successful': (r) => r.json('success') === true,
  });
  
  if (executeRes.status === 200 && executeRes.json('success') === true) {
    successfulMigrations.add(1);
  } else {
    failedMigrations.add(1);
  }
  
  // Longer sleep after heavy operation
  sleep(3);
}

// Main function that distributes requests based on scenario
export default function() {
  const scenario = __ENV.SCENARIO;
  
  if (scenario === 'migration_execution') {
    executeMigration();
  } else {
    // Default to API status tests for other scenarios
    apiStatus();
    validateMigrations();
  }
}
