from datetime import datetime
from typing import Literal
from pydantic import BaseModel, ConfigDict, Field, field_validator

Status = Literal["TODO", "IN_PROGRESS", "DONE"]
Priority = Literal["LOW", "MEDIUM", "HIGH"]
Category = Literal["ACCESS", "NETWORK", "APPLICATION", "HARDWARE", "OTHER"]

class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)
    description: str = ""
    priority: Priority = "MEDIUM"
    status: Status = "TODO"
    assignee: str = Field(default="Unassigned", min_length=1, max_length=120)
    requester: str = Field(default="Unknown", min_length=1, max_length=120)
    category: Category = "OTHER"

class TaskUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = None
    priority: Priority | None = None
    status: Status | None = None
    assignee: str | None = Field(default=None, min_length=1, max_length=120)
    requester: str | None = Field(default=None, min_length=1, max_length=120)
    category: Category | None = None

    @field_validator("title", "description", "priority", "status", "assignee", "requester", "category", mode="before")
    @classmethod
    def reject_explicit_null(cls, value):
        if value is None:
            raise ValueError("Ticket fields cannot be null")
        return value

class TaskOut(TaskCreate):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

class StatsOut(BaseModel):
    total: int
    todo: int
    inProgress: int
    done: int
