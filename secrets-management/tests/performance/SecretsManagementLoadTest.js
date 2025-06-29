import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const encryptionTimes = new Trend('encryption_times');
const decryptionTimes = new Trend('decryption_times');
const secretCreateTimes = new Trend('secret_create_times');
const secretReadTimes = new Trend('secret_read_times');
const failedEncryptions = new Counter('failed_encryptions');
const failedDecryptions = new Counter('failed_decryptions');

// Test configuration
export const options = {
  scenarios: {
    // API endpoint testing
    api_endpoints: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '20s', target: 10 },  // Ramp up
        { duration: '30s', target: 20 },  // Increase load
        { duration: '1m', target: 20 },   // Maintain load
        { duration: '20s', target: 0 },   // Ramp down
      ],
    },
    
    // Encryption/Decryption performance
    crypto_operations: {
      executor: 'constant-arrival-rate',
      rate: 50,                          // 50 iterations per timeUnit
      timeUnit: '1m',                    // 50 iterations per minute
      duration: '2m',                    // Run for 2 minutes
      preAllocatedVUs: 10,               // Allocate 10 VUs initially
      maxVUs: 20,                        // Maximum 20 VUs
      startTime: '30s',                  // Start after the API endpoint scenario has begun
    },
    
    // Secret management operations (create/read/update)
    secret_management: {
      executor: 'per-vu-iterations',
      vus: 5,                            // 5 concurrent users
      iterations: 10,                    // Each user performs 10 operations
      maxDuration: '3m',                 // Maximum duration of 3 minutes
      startTime: '1m30s',                // Start after other scenarios have begun
    }
  },
  
  thresholds: {
    http_req_duration: ['p(95)<1000'],   // 95% of requests complete within 1s
    http_req_failed: ['rate<0.01'],      // Less than 1% of requests should fail
    'encryption_times': ['p(95)<200'],   // 95% of encryptions under 200ms
    'decryption_times': ['p(95)<50'],    // 95% of decryptions under 50ms
    'secret_create_times': ['p(95)<500'],// 95% of secret creations under 500ms
    'secret_read_times': ['p(95)<100'],  // 95% of secret reads under 100ms
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
  
  // Check secrets list endpoint
  const listRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/secrets?limit=10`, 
    { headers: getAuthHeaders() }
  );
  
  check(listRes, {
    'list secrets returns 200': (r) => r.status === 200,
    'list secrets returns array': (r) => Array.isArray(r.json()),
  });
  
  sleep(Math.random() * 1 + 0.5);
}

// Crypto operations testing
export function testCryptoOperations() {
  // Generate random content for encryption
  const data = JSON.stringify({
    value: `test-secret-${Math.random().toString(36).substring(2, 10)}`,
  });
  
  // Test encryption
  const encryptStartTime = new Date().getTime();
  const encryptRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/crypto/encrypt`,
    data,
    { headers: getAuthHeaders() }
  );
  const encryptEndTime = new Date().getTime();
  encryptionTimes.add(encryptEndTime - encryptStartTime);
  
  // Check encryption result
  const encryptionPassed = check(encryptRes, {
    'encrypt returns 200': (r) => r.status === 200,
    'encrypted value is returned': (r) => r.json('encryptedValue') !== undefined,
  });
  
  if (!encryptionPassed) {
    failedEncryptions.add(1);
    sleep(1);
    return;
  }
  
  // Test decryption with result from encryption
  const encryptedValue = encryptRes.json('encryptedValue');
  const decryptData = JSON.stringify({
    encryptedValue: encryptedValue,
  });
  
  const decryptStartTime = new Date().getTime();
  const decryptRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/crypto/decrypt`,
    decryptData,
    { headers: getAuthHeaders() }
  );
  const decryptEndTime = new Date().getTime();
  decryptionTimes.add(decryptEndTime - decryptStartTime);
  
  // Check decryption result
  const decryptionPassed = check(decryptRes, {
    'decrypt returns 200': (r) => r.status === 200,
    'decrypted value matches original': (r) => {
      const originalValue = JSON.parse(data).value;
      return r.json('value') === originalValue;
    },
  });
  
  if (!decryptionPassed) {
    failedDecryptions.add(1);
  }
  
  sleep(Math.random() * 0.5 + 0.5);
}

// Secret management operations
export function manageSecrets() {
  // Create unique identifiers for this test run
  const testId = Math.random().toString(36).substring(2, 10);
  const secretName = `perf-test-secret-${testId}`;
  const secretValue = `test-value-${testId}`;
  const environment = ['dev', 'test', 'staging', 'prod'][Math.floor(Math.random() * 4)];
  
  // 1. Create a secret
  const createData = JSON.stringify({
    name: secretName,
    environment: environment,
    value: secretValue,
    description: `Performance test secret ${testId}`,
  });
  
  const createStartTime = new Date().getTime();
  const createRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/secrets`,
    createData,
    { headers: getAuthHeaders() }
  );
  const createEndTime = new Date().getTime();
  secretCreateTimes.add(createEndTime - createStartTime);
  
  // Check creation result
  const createPassed = check(createRes, {
    'create secret returns 201': (r) => r.status === 201,
    'created secret has ID': (r) => r.json('id') !== undefined,
  });
  
  if (!createPassed) {
    console.log(`Failed to create secret: ${createRes.status} - ${createRes.body}`);
    sleep(2);
    return;
  }
  
  const secretId = createRes.json('id');
  
  // 2. Read the secret value
  const readStartTime = new Date().getTime();
  const readRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/secrets/values/${secretName}?environment=${environment}`,
    { headers: getAuthHeaders() }
  );
  const readEndTime = new Date().getTime();
  secretReadTimes.add(readEndTime - readStartTime);
  
  check(readRes, {
    'read secret returns 200': (r) => r.status === 200,
    'read secret returns correct value': (r) => r.body === secretValue,
  });
  
  // 3. Update the secret
  const updateData = JSON.stringify({
    value: `${secretValue}-updated`,
    description: `Updated performance test secret ${testId}`,
  });
  
  const updateRes = http.put(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/secrets/${secretId}`,
    updateData,
    { headers: getAuthHeaders() }
  );
  
  check(updateRes, {
    'update secret returns 200': (r) => r.status === 200,
    'updated secret has same ID': (r) => r.json('id') === secretId,
  });
  
  // 4. Clean up - delete the secret
  const deleteRes = http.del(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/secrets/${secretId}`,
    null,
    { headers: getAuthHeaders() }
  );
  
  check(deleteRes, {
    'delete secret returns 204': (r) => r.status === 204,
  });
  
  sleep(Math.random() * 1 + 1);
}

// Main function
export default function() {
  // Select function based on scenario
  const scenario = __ENV.SCENARIO;
  
  switch(scenario) {
    case 'crypto_operations':
      testCryptoOperations();
      break;
      
    case 'secret_management':
      manageSecrets();
      break;
      
    default:
      // Default to basic API endpoint testing
      checkEndpoints();
  }
}
