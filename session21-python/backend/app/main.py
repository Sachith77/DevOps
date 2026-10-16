from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from prometheus_fastapi_instrumentator import Instrumentator

from .config import settings
from .db import get_db
from .models import Task
from .schemas import Category, StatsOut, Status, TaskCreate, TaskOut, TaskUpdate

app = FastAPI(title=settings.app_name, version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])
Instrumentator().instrument(app).expose(app, endpoint="/metrics")

@app.get("/")
def root():
    return {"service": settings.app_name, "version": "1.0.0", "docs": "/docs"}

@app.get("/health")
def health():
    return {"status": "UP"}

@app.get("/ready")
def ready(db: Session = Depends(get_db)):
    db.execute(select(func.count(Task.id)))
    return {"status": "READY"}

@app.get("/api/tasks", response_model=list[TaskOut], include_in_schema=False)
@app.get("/api/tickets", response_model=list[TaskOut])
def list_tasks(status: Status | None = None, category: Category | None = None, db: Session = Depends(get_db)):
    query = select(Task).order_by(Task.id.desc())
    if status:
        query = query.where(Task.status == status)
    if category:
        query = query.where(Task.category == category)
    return list(db.scalars(query))

@app.get("/api/tasks/stats", response_model=StatsOut, include_in_schema=False)
@app.get("/api/tickets/stats", response_model=StatsOut)
def stats(db: Session = Depends(get_db)):
    rows = db.execute(select(Task.status, func.count(Task.id)).group_by(Task.status)).all()
    counts = {status: count for status, count in rows}
    return StatsOut(total=sum(counts.values()), todo=counts.get("TODO", 0), inProgress=counts.get("IN_PROGRESS", 0), done=counts.get("DONE", 0))

@app.get("/api/tasks/{task_id}", response_model=TaskOut, include_in_schema=False)
@app.get("/api/tickets/{task_id}", response_model=TaskOut)
def get_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Ticket not found")
    return task

@app.post("/api/tasks", response_model=TaskOut, status_code=status.HTTP_201_CREATED, include_in_schema=False)
@app.post("/api/tickets", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(payload: TaskCreate, db: Session = Depends(get_db)):
    task = Task(**payload.model_dump())
    db.add(task)
    db.commit()
    db.refresh(task)
    return task

@app.put("/api/tasks/{task_id}", response_model=TaskOut, include_in_schema=False)
@app.put("/api/tickets/{task_id}", response_model=TaskOut)
def update_task(task_id: int, payload: TaskUpdate, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Ticket not found")
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(task, key, value)
    db.commit()
    db.refresh(task)
    return task

@app.delete("/api/tasks/{task_id}", status_code=status.HTTP_204_NO_CONTENT, include_in_schema=False)
@app.delete("/api/tickets/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.get(Task, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Ticket not found")
    db.delete(task)
    db.commit()
