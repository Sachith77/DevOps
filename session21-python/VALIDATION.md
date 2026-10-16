# Validation record - 16 October 2026

These are observed local results, not a claim that the project has been deployed
to AWS or submitted for grading.

| Check | Result |
| --- | --- |
| AWS CLI authentication | Succeeded using the existing local configuration; no keys printed or copied |
| AWS region | ap-southeast-2 |
| Existing EKS clusters in that region | None at the time of inspection |
| Tool discovery | Docker, AWS CLI, Terraform, Helm, kubectl, and Git found |
| Frontend dependencies | npm lockfile created; npm audit reported zero findings |
| Frontend production build | Passed |
| Backend tests with updated dependencies | 25 passed in Python 3.12; isolated SQLite per test |
| Docker Compose | PostgreSQL healthy; backend and frontend running |
| PostgreSQL migration | Applied 0001 -> 0002; four existing records preserved |
| API readiness | GET /ready returned READY |
| Frontend API proxy | GET localhost:3000/api/tickets/stats returned database counts |
| Live API integration | Create/update/filter/delete passed through Nginx against PostgreSQL; temporary ticket removed |
| Backend container identity | UID 10001, non-root |
| Frontend container identity | UID 101, non-root |
| Trivy backend image | Zero fixable HIGH/CRITICAL findings |
| Trivy frontend image | Zero fixable HIGH/CRITICAL findings |
| Helm lint | Passed with --strict |
| Production Helm render | Parsed successfully; both Ingress service ports resolve |
| Argo CD values paths | Both value files resolve within the repository |
| Bootstrap dependencies | Pinned ALB controller, Prometheus stack, and Argo CD charts rendered and parsed; IAM role annotation verified |
| Grafana dashboard | ConfigMap and JSON parsed; three panels present |
| PowerShell scripts | Parsed without syntax errors; preflight executed successfully |
| GitHub workflow | actionlint passed, including shellcheck |
| Terraform init | Succeeded; provider lockfile retained for commit |
| Terraform validate | Succeeded |
| Terraform plan | 67 to add, 0 to change, 0 to destroy in Sydney |

Trivy uses HIGH/CRITICAL severity and ignores unfixed findings, matching the
reference policy. An initial unrestricted backend scan did find unfixed OS
vulnerabilities. A passing gate does not imply an entirely vulnerability-free
image. Reports are retained in ignored `artifacts/` files; CI uploads reports as
workflow artifacts.

There is one test-client deprecation warning about Starlette's httpx integration.
It does not fail the suite.

A PostgreSQL backup from before migration is retained outside the repository at
`%TEMP%/herodesk-before-migration.sql`.

## Checks requiring a later run

- The browser automation service was unavailable; no browser UI walkthrough or
  updated screenshot is claimed. Open http://localhost:3000 to inspect HeroDesk.
- The selected Minikube context refused its API connection. No existing local
  cluster workloads were changed.
- Cloud validation is now in progress following the user's request. Terraform
  apply is creating the lab; GitHub delivery and EKS bootstrap results will be
  recorded after completion. The user requested destruction after validation.
- The 11-slide presentation is in repository-root demo/. A real narrated video
  and the manual captures listed in demo/SCREENSHOTS.md are still required.

The saved local Terraform plan is ignored. Review it again before applying if
configuration or AWS state changes.
