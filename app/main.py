import time
import os
import psutil
from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel
from typing import List, Dict

app = FastAPI(
    title="DevOps Technical Assignment API",
    description="A production-ready FastAPI service designed for Cloud deployment, CI/CD, and performance load testing.",
    version="1.0.0"
)

# Simulated in-memory database
db_mock: List[Dict[str, str]] = [
    {"id": "1", "item": "AWS EC2 Instance Setup", "status": "Completed"},
    {"id": "2", "item": "Terraform Infrastructure Provisioning", "status": "Completed"},
    {"id": "3", "item": "CI/CD Pipeline Setup", "status": "In Progress"}
]

class Item(BaseModel):
    id: str
    item: str
    status: str

def fibonacci(n: int) -> int:
    if n <= 1:
        return n
    a, b = 0, 1
    for _ in range(2, n + 1):
        a, b = b, a + b
    return b

@app.get("/", tags=["Health"])
def read_root():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "environment": os.getenv("APP_ENV", "production"),
        "service": "devops-assignment-api"
    }

@app.get("/api/v1/data", response_model=List[Dict[str, str]], tags=["Data Store"])
def get_items():
    """Simulated database read operation with artificial database latency."""
    time.sleep(0.05)  # 50ms mock DB latency
    return db_mock

@app.post("/api/v1/data", status_code=status.HTTP_201_CREATED, response_model=Item, tags=["Data Store"])
def create_item(item: Item):
    """Simulated database write operation."""
    for existing in db_mock:
        if existing["id"] == item.id:
            raise HTTPException(status_code=400, detail="Item already exists")
    db_mock.append(item.dict())
    return item

@app.get("/api/v1/compute", tags=["Performance Testing"])
def compute_load(n: int = 30):
    """CPU intensive endpoint to simulate computational load (Fibonacci)."""
    if n < 0 or n > 40:
        raise HTTPException(status_code=400, detail="Parameter 'n' must be between 0 and 40 to prevent crashing the server.")
    
    start_time = time.time()
    result = fibonacci(n)
    duration = time.time() - start_time
    
    return {
        "operation": f"Fibonacci({n})",
        "result": result,
        "execution_time_seconds": duration,
        "cpu_usage_percent": psutil.cpu_percent()
    }

@app.get("/api/v1/memory", tags=["Performance Testing"])
def memory_load(size_mb: int = 10):
    """Memory intensive endpoint to simulate memory allocation load."""
    if size_mb < 1 or size_mb > 100:
        raise HTTPException(status_code=400, detail="Size must be between 1 and 100 MB.")
    
    start_time = time.time()
    # Allocate approximately size_mb of memory in a byte string
    dummy_data = b"x" * (size_mb * 1024 * 1024)
    data_len = len(dummy_data)
    duration = time.time() - start_time
    
    # Check RAM usage
    mem_info = psutil.virtual_memory()
    
    return {
        "allocated_mb": size_mb,
        "bytes_allocated": data_len,
        "execution_time_seconds": duration,
        "system_memory_used_percent": mem_info.percent,
        "system_memory_available_mb": mem_info.available // (1024 * 1024)
    }

@app.get("/api/v1/system-stats", tags=["Monitoring"])
def get_system_stats():
    """Retrieve current system-level metrics (CPU, RAM, Disk)."""
    return {
        "cpu_count": psutil.cpu_count(),
        "cpu_percent": psutil.cpu_percent(interval=None),
        "memory_percent": psutil.virtual_memory().percent,
        "memory_used_mb": psutil.virtual_memory().used // (1024 * 1024),
        "memory_total_mb": psutil.virtual_memory().total // (1024 * 1024),
        "disk_percent": psutil.disk_usage('/').percent
    }
