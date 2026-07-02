from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"
    assert "timestamp" in response.json()

def test_get_items():
    response = client.get("/api/v1/data")
    assert response.status_code == 200
    assert len(response.json()) >= 3
    assert response.json()[0]["id"] == "1"

def test_create_item():
    new_item = {"id": "4", "item": "CloudWatch Dashboard Setup", "status": "Pending"}
    response = client.post("/api/v1/data", json=new_item)
    assert response.status_code == 201
    assert response.json() == new_item

    # Verify duplicate prevention
    response = client.post("/api/v1/data", json=new_item)
    assert response.status_code == 400

def test_compute_load():
    response = client.get("/api/v1/compute?n=10")
    assert response.status_code == 200
    assert response.json()["operation"] == "Fibonacci(10)"
    assert response.json()["result"] == 55
    assert "execution_time_seconds" in response.json()

def test_compute_load_validation():
    response = client.get("/api/v1/compute?n=45")
    assert response.status_code == 400

def test_memory_load():
    response = client.get("/api/v1/memory?size_mb=1")
    assert response.status_code == 200
    assert response.json()["allocated_mb"] == 1
    assert "system_memory_used_percent" in response.json()

def test_system_stats():
    response = client.get("/api/v1/system-stats")
    assert response.status_code == 200
    assert "cpu_percent" in response.json()
    assert "memory_percent" in response.json()
