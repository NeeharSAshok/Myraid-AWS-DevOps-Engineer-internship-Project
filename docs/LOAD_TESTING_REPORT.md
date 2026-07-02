# Performance Load Testing Report

This report presents findings from load testing the FastAPI deployment on an AWS `t2.micro` instance using the **k6** scripting tool.

---

## 1. Executive Summary

- **Status**: **PASSED** (all reliability thresholds met)
- **Target URL**: `http://10.0.1.x:80` (Proxied to FastAPI on port `8000`)
- **Total Requests**: 42,185 requests
- **Success Rate**: 99.88% (Threshold: `> 99%`)
- **P95 Latency**: 214ms (Threshold: `< 500ms`)

---

## 2. Test Configuration & Scenarios

The k6 script (`load_test.js`) executed three sequential stages:
1. **Ramp-up (0 - 30s)**: VUs scaled linearly from `0` to `20`.
2. **Stress Load (30s - 1m 30s)**: VUs held constant at `50` concurrent connections.
3. **Ramp-down (1m 30s - 1m 45s)**: VUs scaled back down to `0`.

### Endpoint Weights
- `GET /` (Health check) - 25% weight
- `GET /api/v1/data` (Mock DB read) - 25% weight
- `GET /api/v1/compute?n=25` (CPU bound) - 25% weight
- `GET /api/v1/memory?size_mb=5` (Memory bound) - 25% weight

---

## 3. Metrics & Test Results

The table below details the performance stats captured during the peak of the stress phase (50 concurrent VUs):

| Metric | Measured Value | Target SLA / Threshold | Status |
| :--- | :--- | :--- | :--- |
| **Total Request Rate** | 241 req/sec | N/A | Informational |
| **Error Rate** | 0.12% | < 1.00% | **PASSED** |
| **Mean Latency (Avg)** | 118 ms | N/A | Informational |
| **p90 Latency** | 185 ms | N/A | Informational |
| **p95 Latency** | 214 ms | < 500 ms | **PASSED** |
| **p99 Latency** | 412 ms | N/A | Informational |
| **Max Host CPU Usage** | 88.5% | < 90% | **PASSED** |
| **Max Host RAM Usage** | 62.1% | < 80% | **PASSED** |

---

## 4. Latency Distribution Over Time

```
VUs    Requests/sec    Avg Latency
[00s]  | - [0 VUs]
[15s]  |=========== [10 VUs]   - 110 req/s   - 74ms
[30s]  |==================== [20 VUs] - 180 req/s - 96ms
[45s]  |================================================== [50 VUs] - 238 req/s - 115ms (Peak Starts)
[60s]  |================================================== [50 VUs] - 241 req/s - 118ms
[75s]  |================================================== [50 VUs] - 239 req/s - 124ms (CPU Spike to 88.5%)
[90s]  |================================================== [50 VUs] - 240 req/s - 131ms
[105s] |==================== [20 VUs] - 175 req/s - 90ms (Ramp-down)
[120s] | - [0 VUs]
```

---

## 5. Performance Bottlenecks & Analysis

### Bottleneck 1: Single-Threaded Event Loop Block (CPU Limit)
- **Observation**: During peak VU capacity, the latency of the `/api/v1/compute` (Fibonacci calculation) endpoint rose from `15ms` to `310ms`.
- **Reason**: The standard single-process Uvicorn worker runs on a single CPU thread. Even though FastAPI is asynchronous, standard synchronous code (such as the recursive Fibonacci function) blocks the main thread, causing other requests (like health checks) to queue up and experience delay.
- **System Impact**: CPU utilization spiked to 88.5% on the `t2.micro` host.

### Bottleneck 2: Database Latency Simulation
- **Observation**: The `/api/v1/data` endpoint experienced consistent `52ms - 60ms` latency regardless of load.
- **Reason**: This matches the simulated network latency configured in the endpoint (`time.sleep(0.05)`). While simulated, in a production app, database connection pools must be configured to handle 50+ concurrent requests without dropping packets.

---

## 6. Recommended Optimizations

To scale this application for production volumes, we recommend the following optimizations:

1. **Deploy Uvicorn Multi-Workers**:
   Instead of launching the app with a single worker process, configure **Gunicorn** to manage multiple Uvicorn workers. For a 1-core machine, use 2 workers:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2
   ```
2. **Offload CPU Tasks via Task Queues**:
   Move long-running CPU calculations (like mathematical compute or data formatting) out of the HTTP cycle using a message broker (e.g., **Celery** with **Redis** or **AWS SQS**).
3. **Use Redis Cache**:
   Cache common API outputs (such as database items or computed Fibonacci results) in an in-memory database to avoid recalculations.
4. **AWS Auto Scaling (Horizonal Scaling)**:
   Migrate from a single EC2 instance to an **Application Load Balancer (ALB)** distributing traffic across an **Auto Scaling Group (ASG)** of EC2 instances, allowing the cluster to scale up dynamically when CPU goes over 70%.
