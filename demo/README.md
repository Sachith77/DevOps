# HeroDesk submission artifacts

- [Screenshot checklist](SCREENSHOTS.md): exact filenames, commands, and expected results.
- `presentation.pptx`: editable presentation covering the project and architecture.
- `evidence/`: real command output captured during validation.
- `screenshots/`: place manual browser, console, and terminal captures here.
- `walkthrough.mp4`: add your narrated recording, or provide a GitHub release link below.

**Presentation video:** pending a real narrated recording.

Follow [the complete project runbook](../README.md). Present the slides first,
then show code, CI, security reports, GHCR SHA tags, Terraform and AWS, Argo CD
Synced/Healthy, Kubernetes workloads and Ingress, Prometheus Targets UP, and
populated Grafana panels. Show a disposable troubleshooting exercise and cleanup.

Cloud resources are scheduled for teardown at the user's request after validation.
Use the saved validation output to distinguish completed work from screenshots
that still require a new live deployment. Do not invent a screenshot of a run
that has already been destroyed.
