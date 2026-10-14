import os
os.environ["DATABASE_URL"] = "sqlite:///./test.db"

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.db import Base, engine

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)
    if os.path.exists("./test.db"):
        try:
            os.remove("./test.db")
        except OSError:
            pass

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}

def test_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["service"] == "DevOps HeroBoard API"
    assert response.json()["version"] == "1.0.0"

def test_ready():
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json() == {"status": "READY"}

def test_create_task():
    payload = {
        "title": "Configure EKS Cluster",
        "description": "Deploy AWS EKS managed node groups via Terraform",
        "priority": "HIGH",
        "assignee": "Sachith Reddy"
    }
    response = client.post("/api/tasks", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == payload["title"]
    assert data["priority"] == "HIGH"
    assert data["assignee"] == "Sachith Reddy"
    assert data["status"] == "TODO"
    assert "id" in data

def test_list_tasks():
    response = client.get("/api/tasks")
    assert response.status_code == 200
    tasks = response.json()
    assert isinstance(tasks, list)
    assert len(tasks) >= 1

def test_get_task_by_id():
    create_res = client.post("/api/tasks", json={
        "title": "Set up Prometheus & Grafana",
        "priority": "MEDIUM",
        "assignee": "Sachith Reddy"
    })
    task_id = create_res.json()["id"]

    response = client.get(f"/api/tasks/{task_id}")
    assert response.status_code == 200
    assert response.json()["id"] == task_id
    assert response.json()["title"] == "Set up Prometheus & Grafana"

def test_update_task():
    create_res = client.post("/api/tasks", json={
        "title": "Automate CI/CD pipeline",
        "priority": "HIGH",
        "assignee": "Sachith Reddy"
    })
    task_id = create_res.json()["id"]

    update_res = client.put(f"/api/tasks/{task_id}", json={
        "status": "IN_PROGRESS",
        "priority": "HIGH"
    })
    assert update_res.status_code == 200
    assert update_res.json()["status"] == "IN_PROGRESS"

def test_task_stats():
    response = client.get("/api/tasks/stats")
    assert response.status_code == 200
    stats = response.json()
    assert "total" in stats
    assert "todo" in stats
    assert "inProgress" in stats
    assert "done" in stats
    assert stats["total"] >= 1

def test_delete_task():
    create_res = client.post("/api/tasks", json={
        "title": "Temporary cleanup test task",
        "priority": "LOW",
        "assignee": "Sachith Reddy"
    })
    task_id = create_res.json()["id"]

    del_res = client.delete(f"/api/tasks/{task_id}")
    assert del_res.status_code == 204

    get_res = client.get(f"/api/tasks/{task_id}")
    assert get_res.status_code == 404

def test_get_nonexistent_task():
    response = client.get("/api/tasks/999999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Task not found"
