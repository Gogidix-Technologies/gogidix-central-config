import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Trend } from 'k6/metrics';

// Custom metrics
const planCreationTimes = new Trend('plan_creation_times');
const executionStartTimes = new Trend('execution_start_times');
const simulationStartTimes = new Trend('simulation_start_times');
const failedCreations = new Counter('failed_creations');
const failedExecutions = new Counter('failed_executions');
const failedSimulations = new Counter('failed_simulations');

// Test configuration
export const options = {
  scenarios: {
    // API endpoint testing
    api_endpoints: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '15s', target: 10 },  // Ramp up
        { duration: '30s', target: 20 },  // Increase load
        { duration: '1m', target: 20 },   // Maintain load
        { duration: '15s', target: 0 },   // Ramp down
      ],
    },
    
    // Plan creation and validation operations
    plan_operations: {
      executor: 'constant-arrival-rate',
      rate: 30,                          // 30 iterations per timeUnit
      timeUnit: '1m',                    // 30 iterations per minute
      duration: '2m',                    // Run for 2 minutes
      preAllocatedVUs: 10,               // Allocate 10 VUs initially
      maxVUs: 20,                        // Maximum 20 VUs
      startTime: '30s',                  // Start after the API endpoint scenario has begun
    },
    
    // Recovery simulation operations
    simulation_operations: {
      executor: 'per-vu-iterations',
      vus: 5,                            // 5 concurrent users
      iterations: 10,                    // Each user performs 10 operations
      maxDuration: '3m',                 // Maximum duration of 3 minutes
      startTime: '1m30s',                // Start after other scenarios have begun
    }
  },
  
  thresholds: {
    http_req_duration: ['p(95)<1500'],   // 95% of requests complete within 1.5s
    http_req_failed: ['rate<0.02'],      // Less than 2% of requests should fail
    'plan_creation_times': ['p(95)<800'],   // 95% of plan creations under 800ms
    'execution_start_times': ['p(95)<500'], // 95% of execution starts under 500ms
    'simulation_start_times': ['p(95)<700'],  // 95% of simulation starts under 700ms
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
  
  // Check recovery plans list endpoint
  const listRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans?limit=10`, 
    { headers: getAuthHeaders() }
  );
  
  check(listRes, {
    'list plans returns 200': (r) => r.status === 200,
    'list plans returns array': (r) => Array.isArray(r.json()),
  });
  
  sleep(Math.random() * 1 + 0.5);
}

// Plan creation and validation testing
export function testPlanCreation() {
  // Generate a test recovery plan
  const testId = Math.random().toString(36).substring(2, 10);
  const planData = JSON.stringify({
    name: `perf-test-plan-${testId}`,
    description: `Performance test recovery plan ${testId}`,
    trigger: "MANUAL",
    targetRTO: 180,
    targetRPO: 60,
    steps: createTestSteps()
  });
  
  // Measure plan creation time
  const startTime = new Date().getTime();
  const createRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans`,
    planData,
    { headers: getAuthHeaders() }
  );
  const endTime = new Date().getTime();
  
  planCreationTimes.add(endTime - startTime);
  
  const creationPassed = check(createRes, {
    'plan creation returns 201': (r) => r.status === 201,
    'created plan has id': (r) => r.json('id') !== undefined,
  });
  
  if (!creationPassed) {
    failedCreations.add(1);
    sleep(1);
    return;
  }
  
  const planId = createRes.json('id');
  
  // Test plan validation
  const validationRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans/validate`,
    planData,
    { headers: getAuthHeaders() }
  );
  
  check(validationRes, {
    'validation returns 200': (r) => r.status === 200,
    'validation result is returned': (r) => r.json('valid') !== undefined,
  });
  
  // Clean up the created plan
  http.del(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans/${planId}`,
    null,
    { headers: getAuthHeaders() }
  );
  
  sleep(Math.random() * 0.5 + 0.2);
}

// Recovery execution simulation testing
export function testRecoverySim() {
  // Create a recovery plan for simulation
  const testId = Math.random().toString(36).substring(2, 10);
  const planData = JSON.stringify({
    name: `sim-test-plan-${testId}`,
    description: `Simulation test plan ${testId}`,
    trigger: "MANUAL",
    targetRTO: 120,
    targetRPO: 30,
    steps: createSimulationSteps()
  });
  
  // Create the plan
  const createRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans`,
    planData,
    { headers: getAuthHeaders() }
  );
  
  const creationPassed = check(createRes, {
    'simulation plan creation returns 201': (r) => r.status === 201,
    'simulation plan has id': (r) => r.json('id') !== undefined,
  });
  
  if (!creationPassed) {
    failedSimulations.add(1);
    sleep(1);
    return;
  }
  
  const planId = createRes.json('id');
  
  // Measure simulation start time
  const simStartTime = new Date().getTime();
  const simRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans/${planId}/simulate`,
    null,
    { headers: getAuthHeaders() }
  );
  const simEndTime = new Date().getTime();
  
  simulationStartTimes.add(simEndTime - simStartTime);
  
  const simPassed = check(simRes, {
    'simulation start returns 202': (r) => r.status === 202,
    'simulation has id': (r) => r.json('simulationId') !== undefined,
  });
  
  if (!simPassed) {
    failedSimulations.add(1);
  } else {
    const simId = simRes.json('simulationId');
    
    // Check simulation status
    sleep(2); // Wait briefly for simulation to start
    
    const statusRes = http.get(
      `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-simulations/${simId}`,
      { headers: getAuthHeaders() }
    );
    
    check(statusRes, {
      'simulation status returns 200': (r) => r.status === 200,
      'simulation status contains results': (r) => r.json('stepResults') !== undefined,
    });
  }
  
  // Measure dry run execution start time
  const execStartTime = new Date().getTime();
  const execRes = http.post(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans/${planId}/execute?dryRun=true`,
    null,
    { headers: getAuthHeaders() }
  );
  const execEndTime = new Date().getTime();
  
  executionStartTimes.add(execEndTime - execStartTime);
  
  const execPassed = check(execRes, {
    'execution start returns 202': (r) => r.status === 202,
    'execution has id': (r) => r.json('executionId') !== undefined,
  });
  
  if (!execPassed) {
    failedExecutions.add(1);
  }
  
  // Clean up the created plan
  http.del(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-plans/${planId}`,
    null,
    { headers: getAuthHeaders() }
  );
  
  sleep(Math.random() * 1 + 0.5);
}

// Test quick stats and history requests
export function testStatistics() {
  // Get recovery execution history
  const historyRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-executions/history?limit=5`,
    { headers: getAuthHeaders() }
  );
  
  check(historyRes, {
    'history request returns 200': (r) => r.status === 200,
    'history returns array': (r) => Array.isArray(r.json()),
  });
  
  // Get recovery statistics
  const statsRes = http.get(
    `${__ENV.BASE_URL || 'http://localhost:8080'}/api/recovery-statistics`,
    { headers: getAuthHeaders() }
  );
  
  check(statsRes, {
    'statistics request returns 200': (r) => r.status === 200,
    'statistics includes success rate': (r) => r.json('successRate') !== undefined,
    'statistics includes avg execution time': (r) => r.json('averageExecutionTimeMs') !== undefined,
  });
  
  sleep(Math.random() * 0.5);
}

// Main function
export default function() {
  // Select function based on scenario
  const scenario = __ENV.SCENARIO;
  
  switch(scenario) {
    case 'plan_operations':
      testPlanCreation();
      break;
      
    case 'simulation_operations':
      testRecoverySim();
      break;
      
    case 'stats':
      testStatistics();
      break;
      
    default:
      // Default to basic API endpoint testing
      checkEndpoints();
  }
}

// Helper functions

function createTestSteps() {
  return [
    {
      order: 1,
      name: "Stop affected services",
      command: "stop-services.sh --region primary",
      timeoutSeconds: 60,
      retryCount: 3
    },
    {
      order: 2,
      name: "Start backup systems",
      command: "start-backups.sh --mode failover",
      timeoutSeconds: 120,
      retryCount: 2,
      dependsOnStepIds: ["step-1"]
    },
    {
      order: 3,
      name: "Update DNS records",
      command: "update-dns.sh --target backup",
      timeoutSeconds: 60,
      retryCount: 3,
      dependsOnStepIds: ["step-2"]
    }
  ];
}

function createSimulationSteps() {
  return [
    {
      order: 1,
      name: "Check system health",
      command: "check-health.sh",
      timeoutSeconds: 30,
      retryCount: 2
    },
    {
      order: 2,
      name: "Simulate database failure",
      command: "simulate-failure.sh --component database",
      timeoutSeconds: 30,
      retryCount: 1
    },
    {
      order: 3,
      name: "Trigger failover",
      command: "trigger-failover.sh",
      timeoutSeconds: 60,
      retryCount: 3,
      dependsOnStepIds: ["step-2"]
    },
    {
      order: 4,
      name: "Verify recovery",
      command: "verify-recovery.sh",
      timeoutSeconds: 45,
      retryCount: 2,
      dependsOnStepIds: ["step-3"]
    }
  ];
}
