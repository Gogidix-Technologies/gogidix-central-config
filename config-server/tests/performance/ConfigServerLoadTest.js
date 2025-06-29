import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter } from 'k6/metrics';

// Create a counter for successful and failed requests
const successCounter = new Counter('successful_requests');
const failureCounter = new Counter('failed_requests');

// Configuration for the load test
export const options = {
  // Test will run with 50 virtual users
  vus: 50,
  // For a period of 30 seconds
  duration: '30s',
  // Define thresholds for when the test fails
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should complete within 500ms
    http_req_failed: ['rate<0.01'],   // Less than 1% of requests should fail
  },
};

// Define test scenario
export default function() {
  // Set up basic auth credentials
  const credentials = `user:password`; // These would be your actual test credentials
  const encodedCredentials = btoa(credentials);
  
  const params = {
    headers: {
      'Authorization': `Basic ${encodedCredentials}`,
    },
  };

  // Test health endpoint
  let healthResponse = http.get('http://localhost:8888/actuator/health');
  check(healthResponse, {
    'health status is 200': (r) => r.status === 200,
    'health response time < 200ms': (r) => r.timings.duration < 200,
  });
  
  if (healthResponse.status === 200) {
    successCounter.add(1);
  } else {
    failureCounter.add(1);
  }

  // Test configuration endpoint with authentication
  let configResponse = http.get('http://localhost:8888/config/application/default', params);
  check(configResponse, {
    'config status is 200': (r) => r.status === 200,
    'config response time < 300ms': (r) => r.timings.duration < 300,
  });
  
  if (configResponse.status === 200) {
    successCounter.add(1);
  } else {
    failureCounter.add(1);
  }

  // Add random sleep time between 1-2 seconds to simulate real user behavior
  sleep(Math.random() * 1 + 1);
}
