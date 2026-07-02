import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metric to track error rate
export const errorRate = new Rate('errors');

// Test options: Ramping virtual users (VUs) up, holding, and ramping down
export const options = {
  stages: [
    { duration: '30s', target: 20 },  // Ramp-up to 20 users
    { duration: '1m', target: 50 },   // Stress phase: 50 users
    { duration: '15s', target: 0 },   // Ramp-down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    errors: ['rate<0.01'],            // Error rate must be less than 1%
  },
};

// Base URL configuration (passed via environment variable or default to localhost)
const BASE_URL = __ENV.TARGET_URL || 'http://localhost:8000';

export default function () {
  // 1. Health check endpoint (lightweight GET)
  const healthRes = http.get(`${BASE_URL}/`);
  check(healthRes, {
    'health check status is 200': (r) => r.status === 200,
    'health check is healthy': (r) => JSON.parse(r.body).status === 'healthy',
  }) || errorRate.add(1);

  sleep(1);

  // 2. Data store read endpoint (simulated 50ms database latency GET)
  const dataRes = http.get(`${BASE_URL}/api/v1/data`);
  check(dataRes, {
    'data list status is 200': (r) => r.status === 200,
    'data contains list of items': (r) => Array.isArray(JSON.parse(r.body)),
  }) || errorRate.add(1);

  sleep(1);

  // 3. CPU compute endpoint (moderately intensive CPU task GET)
  // Calculate Fibonacci of 25 (fast enough to not block but exercises CPU)
  const computeRes = http.get(`${BASE_URL}/api/v1/compute?n=25`);
  check(computeRes, {
    'compute status is 200': (r) => r.status === 200,
    'compute returns correct result': (r) => JSON.parse(r.body).result === 75025,
  }) || errorRate.add(1);

  sleep(1);

  // 4. Memory load endpoint (simulated GET allocating 5MB)
  const memoryRes = http.get(`${BASE_URL}/api/v1/memory?size_mb=5`);
  check(memoryRes, {
    'memory allocation status is 200': (r) => r.status === 200,
    'memory allocated successfully': (r) => JSON.parse(r.body).allocated_mb === 5,
  }) || errorRate.add(1);

  sleep(2);
}
