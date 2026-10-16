import os
os.environ["DATABASE_URL"] = "sqlite://"

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app
from app.db import Base, get_db


@pytest.fixture
def client():
    # Each test gets its own database. Tests never connect to local PostgreSQL.
    test_engine = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    Base.metadata.create_all(test_engine)
    sessions = sessionmaker(bind=test_engine)
    def override_db():
        with sessions() as session:
            yield session
    app.dependency_overrides[get_db] = override_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()
    test_engine.dispose()


@pytest.fixture
def ticket(client):
    response = client.post("/api/tickets", json={
        "title": "Office VPN unavailable", "requester": "Finance team",
        "category": "NETWORK", "priority": "HIGH", "assignee": "Sachith Reddy"
    })
    assert response.status_code == 201
    return response.json()


def test_health(client):
    assert client.get("/health").json() == {"status": "UP"}


def test_root(client):
    assert client.get("/").json()["service"] == "HeroDesk Helpdesk API"


def test_ready(client):
    assert client.get("/ready").json() == {"status": "READY"}


def test_create_ticket(ticket):
    assert ticket["requester"] == "Finance team"
    assert ticket["category"] == "NETWORK"
    assert ticket["status"] == "TODO"
    assert ticket["created_at"]


def test_list_tickets(client, ticket):
    assert client.get("/api/tickets").json() == [ticket]


def test_get_ticket(client, ticket):
    assert client.get(f"/api/tickets/{ticket['id']}").json() == ticket


def test_update_preserves_details(client, ticket):
    response = client.put(f"/api/tickets/{ticket['id']}", json={"status": "IN_PROGRESS"})
    assert response.status_code == 200
    assert response.json()["status"] == "IN_PROGRESS"
    assert response.json()["requester"] == ticket["requester"]
    assert response.json()["title"] == ticket["title"]


def test_stats_follow_resolution(client, ticket):
    assert client.get("/api/tickets/stats").json() == {"total": 1, "todo": 1, "inProgress": 0, "done": 0}
    client.put(f"/api/tickets/{ticket['id']}", json={"status": "DONE"})
    assert client.get("/api/tickets/stats").json() == {"total": 1, "todo": 0, "inProgress": 0, "done": 1}


def test_filter_by_category_and_status(client, ticket):
    assert len(client.get("/api/tickets?category=NETWORK&status=TODO").json()) == 1
    assert client.get("/api/tickets?category=ACCESS").json() == []
    assert client.get("/api/tickets?status=DONE").json() == []


def test_delete_ticket(client, ticket):
    assert client.delete(f"/api/tickets/{ticket['id']}").status_code == 204
    assert client.get(f"/api/tickets/{ticket['id']}").status_code == 404
    assert client.get("/api/tickets/stats").json()["total"] == 0


@pytest.mark.parametrize("method", ["get", "put", "delete"])
def test_missing_ticket(client, method):
    kwargs = {"json": {"status": "DONE"}} if method == "put" else {}
    response = getattr(client, method)("/api/tickets/999999", **kwargs)
    assert response.status_code == 404
    assert response.json()["detail"] == "Ticket not found"


@pytest.mark.parametrize("payload", [
    {"title": ""}, {"title": "x", "category": "INVALID"}, {"title": "x", "status": "INVALID"},
    {"title": "x", "priority": "URGENT"}, {"title": "x", "requester": "a" * 121}
])
def test_invalid_create(client, payload):
    assert client.post("/api/tickets", json=payload).status_code == 422
    assert client.get("/api/tickets").json() == []


@pytest.mark.parametrize("field", ["title", "status", "priority", "requester", "category"])
def test_null_update_does_not_corrupt_ticket(client, ticket, field):
    assert client.put(f"/api/tickets/{ticket['id']}", json={field: None}).status_code == 422
    assert client.get(f"/api/tickets/{ticket['id']}").json() == ticket


def test_legacy_tasks_route(client, ticket):
    # Old clients still work after the domain migration.
    assert client.get(f"/api/tasks/{ticket['id']}").json() == ticket


def test_metrics(client):
    client.get("/health")
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
