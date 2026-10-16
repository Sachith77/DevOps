"""Add helpdesk fields while preserving existing HeroBoard tasks."""
from alembic import op
import sqlalchemy as sa

revision = "0002_helpdesk_fields"
down_revision = "0001_create_tasks"
branch_labels = None
depends_on = None


def upgrade():
    op.add_column("tasks", sa.Column("requester", sa.String(120), nullable=False, server_default="Unknown"))
    op.add_column("tasks", sa.Column("category", sa.String(30), nullable=False, server_default="OTHER"))


def downgrade():
    op.drop_column("tasks", "category")
    op.drop_column("tasks", "requester")
