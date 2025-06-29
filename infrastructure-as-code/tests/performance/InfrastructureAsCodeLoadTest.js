import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const templateValidationTimes = new Trend('template_validation_times');
const templateProcessingTimes = new Trend('template_processing_times');
const templateDeploymentTimes = new Trend('template_deployment_times');
const validationErrors = new Counter('validation_errors');

// Test configuration
export const options = {
  scenarios: {
    // API load testing scenario
    api_traffic: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '30s', target: 20 },   // Ramp up to 20 users
        { duration: '1m', target: 20 },    // Stay at 20 users for 1 minute
        { duration: '30s', target: 0 },    // Ramp down to 0
      ],
    },
    
    // Template validation scenario (moderate load)
    template_validation: {
      executor: 'constant-arrival-rate',
      rate: 10,                            // 10 iterations per timeUnit
      timeUnit: '1m',                      // 10 iterations per minute (1 every 6 seconds)
      duration: '2m',                      // Run for 2 minutes
      preAllocatedVUs: 5,                  // Allocate 5 VUs initially
      maxVUs: 10,                          // Maximum 10 VUs to handle rate
      startTime: '20s',                    // Start after the API traffic scenario has begun
    },
    
    // Template deployment scenario (heavy processing, low concurrency)
    template_deployment: {
      executor: 'per-vu-iterations',
      vus: 3,                              // Only 3 VUs for this heavy operation
      iterations: 5,                       // Each VU runs 5 iterations
      maxDuration: '3m',                   // Maximum duration of 3 minutes
      startTime: '2m30s',                  // Start after other scenarios
    }
  },
  
  thresholds: {
    // General HTTP request thresholds
    http_req_duration: ['p(95)<1000'],     // 95% of requests should complete within 1s
    http_req_failed: ['rate<0.01'],        // Less than 1% of requests should fail
    
    // Custom metric thresholds
    'template_validation_times': ['p(95)<500'],    // 95% of validations under 500ms
    'template_processing_times': ['p(95)<2000'],   // 95% of processing under 2s
    'template_deployment_times': ['p(95)<5000'],   // 95% of deployments under 5s (dry-run mode)
  },
};

// Helper for basic auth
const getAuthHeaders = () => ({
  'Authorization': `Basic ${__ENV.AUTH || 'YWRtaW46YWRtaW4='}`, // admin:admin in base64
  'Accept': 'application/json',
});

// Simple endpoint checks
export function checkEndpoints() {
  let responses = http.batch([
    ['GET', `${__ENV.BASE_URL || 'http://localhost:8080'}/actuator/health`, null, { headers: {} }],
    ['GET', `${__ENV.BASE_URL || 'http://localhost:8080'}/api/templates`, null, { headers: getAuthHeaders() }],
  ]);
  
  check(responses[0], {
    'health check returns 200': (r) => r.status === 200,
    'health check reports UP': (r) => r.json('status') === 'UP',
  });
  
  check(responses[1], {
    'templates endpoint returns 200': (r) => r.status === 200,
    'templates endpoint returns array': (r) => Array.isArray(r.json()),
  });
  
  sleep(1);
}

// Template validation test
export function validateTemplate() {
  const startTime = new Date().getTime();
  
  // Generate template content (simple CloudFormation template)
  const templateContent = `{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Resources": {
      "MyBucket": {
        "Type": "AWS::S3::Bucket",
        "Properties": {
          "BucketName": "test-bucket-${Math.floor(Math.random() * 10000)}"
        }
      }
    }
  }`;
  
  // Create a FormData object for multipart request
  const data = {
    file: http.file(templateContent, 'template.json', 'application/json'),
  };
  
  // Send validation request
  const res = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/templates/validate`,
    data,
    { headers: getAuthHeaders() }
  );
  
  const endTime = new Date().getTime();
  templateValidationTimes.add(endTime - startTime);
  
  // Check response
  const passed = check(res, {
    'validate returns 200': (r) => r.status === 200,
    'validation completes': (r) => r.json('valid') !== undefined,
  });
  
  if (!passed || (res.status === 200 && !res.json('valid'))) {
    validationErrors.add(1);
  }
  
  sleep(Math.random() * 2);
}

// Template processing test with parameter substitution
export function processTemplate() {
  const startTime = new Date().getTime();
  
  // Generate template with parameters
  const templateContent = `{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Parameters": {
      "BucketName": {
        "Type": "String",
        "Default": "default-bucket"
      },
      "Environment": {
        "Type": "String",
        "Default": "dev"
      }
    },
    "Resources": {
      "MyBucket": {
        "Type": "AWS::S3::Bucket",
        "Properties": {
          "BucketName": {"Ref": "BucketName"},
          "Tags": [{"Key": "Environment", "Value": {"Ref": "Environment"}}]
        }
      }
    }
  }`;
  
  // Parameters to substitute
  const parameters = {
    BucketName: `performance-test-${Math.floor(Math.random() * 10000)}`,
    Environment: ['dev', 'test', 'staging', 'prod'][Math.floor(Math.random() * 4)]
  };
  
  // Create FormData
  const data = {
    file: http.file(templateContent, 'param-template.json', 'application/json'),
    parameters: http.file(JSON.stringify(parameters), 'parameters.json', 'application/json'),
  };
  
  // Send process request
  const res = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/templates/process`,
    data,
    { headers: getAuthHeaders() }
  );
  
  const endTime = new Date().getTime();
  templateProcessingTimes.add(endTime - startTime);
  
  check(res, {
    'process returns 200': (r) => r.status === 200,
    'processing succeeds': (r) => r.json('processed') === true,
    'processed content contains parameters': (r) => {
      const content = r.json('content');
      return content && content.includes(parameters.BucketName);
    },
  });
  
  sleep(Math.random() * 2 + 1);
}

// Template deployment test (dry run)
export function deployTemplate() {
  const startTime = new Date().getTime();
  
  // Simple template
  const templateContent = `{
    "AWSTemplateFormatVersion": "2010-09-09",
    "Resources": {
      "MyBucket": {
        "Type": "AWS::S3::Bucket"
      }
    }
  }`;
  
  // Create FormData with dry run flag
  const data = {
    file: http.file(templateContent, 'deploy-template.json', 'application/json'),
    stackName: `stack-${Math.floor(Math.random() * 10000)}`,
    dryRun: 'true',  // Important: Only perform dry-run in load tests
    region: ['us-east-1', 'us-west-1', 'eu-west-1'][Math.floor(Math.random() * 3)]
  };
  
  // Send deployment request
  const res = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/templates/deploy`,
    data,
    { headers: getAuthHeaders() }
  );
  
  const endTime = new Date().getTime();
  templateDeploymentTimes.add(endTime - startTime);
  
  check(res, {
    'deploy returns 200': (r) => r.status === 200,
    'deployment starts': (r) => r.json('status') === 'STARTED' || r.json('status') === 'COMPLETED',
    'deployment ID returned': (r) => r.json('deploymentId') && r.json('deploymentId').length > 0,
  });
  
  sleep(Math.random() * 3 + 2);  // Longer sleep after heavy operation
}

// Default function that will be executed by scenarios
export default function() {
  // Select the appropriate function based on the active scenario
  const scenario = __ENV.SCENARIO;
  
  switch(scenario) {
    case 'template_validation':
      validateTemplate();
      break;
      
    case 'template_deployment':
      deployTemplate();
      break;
      
    default:
      // Default to API endpoint checks
      checkEndpoints();
  }
}
