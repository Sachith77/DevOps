"""Serialize migrations across replicas and stop if they cannot complete."""
import os
import subprocess
import time

import psycopg
from .config import settings


def main():
    database_url = settings.database_url.replace("postgresql+psycopg://", "postgresql://", 1)
    for attempt in range(30):
        try:
            connection = psycopg.connect(database_url, autocommit=True, connect_timeout=5)
            break
        except psycopg.OperationalError:
            if attempt == 29:
                raise
            time.sleep(2)
    with connection:
        # Session lock releases automatically if the container exits.
        connection.execute("SELECT pg_advisory_lock(210021)")
        subprocess.run(["alembic", "upgrade", "head"], check=True)
        connection.execute("SELECT pg_advisory_unlock(210021)")
    os.execvp("uvicorn", ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"])


if __name__ == "__main__":
    main()
