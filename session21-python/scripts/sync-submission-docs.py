"""Keep the repository-root submission README in sync with the project runbook."""
from pathlib import Path
import re

project = Path(__file__).resolve().parents[1]
repository = project.parent
source = (project / "README.md").read_text(encoding="utf-8")

def root_link(match):
    label, target = match.groups()
    if target.startswith(("http:", "https:", "#")):
        return match.group(0)
    resolved = (project / target.split("#")[0]).resolve()
    relative = resolved.relative_to(repository).as_posix()
    fragment = "#" + target.split("#", 1)[1] if "#" in target else ""
    return f"[{label}]({relative}{fragment})"

source = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", root_link, source)
source = source.replace("# HeroDesk - Session 21 DevSecOps Capstone", "# HeroDesk - DevSecOps Capstone\n\nApplication source: `session21-python/`. Submission artifacts: `demo/`.", 1)
(repository / "README.md").write_text(source, encoding="utf-8")
print("Updated repository-root README.md")
