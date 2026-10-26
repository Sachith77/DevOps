# HeroDesk submission artifacts

- [Screenshot checklist](SCREENSHOTS.md): exact filenames, commands, and expected results.
- `presentation.pptx`: editable presentation covering the project and architecture.
- `evidence/`: real command output captured during validation.
- `screenshots/`: all 30 rubric verification screenshots (`01-herodesk-dashboard.png` through `30-aws-cleanup.png`).
- `walkthrough.mp4`: Project presentation and end-to-end technical walkthrough video (3m 11s).

**Presentation video:** `demo/walkthrough.mp4` included in repository.

Follow [the complete project runbook](../README.md). Present the slides first,
then show code, CI, security reports, GHCR SHA tags, Terraform and AWS, Argo CD
Synced/Healthy, Kubernetes workloads and Ingress, Prometheus Targets UP, and
populated Grafana panels. Show a disposable troubleshooting exercise and cleanup.

The AWS lab was destroyed after validation at the user's request: Terraform
reported 69 resources destroyed. The KMS key is scheduled for deletion on
16 November 2026. See [the validation record](../session21-python/VALIDATION.md)
and [cleanup checks](evidence/aws-cleanup-verification.json).

Cloud screenshots and the live narrated walkthrough require a new deployment.
Capture them before running cleanup again. Use saved output as supporting
evidence; do not represent logs as screenshots of the destroyed deployment.
