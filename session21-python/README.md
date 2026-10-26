# HeroDesk - Session 21 DevSecOps Capstone

**Author:** Sachith Reddy

**Repository:** [Sachith77/DevOps](https://github.com/Sachith77/DevOps)

HeroDesk is an IT helpdesk for access, network, application, and hardware issues.
Staff create requests; support engineers assign priorities, advance tickets
through Open / Working / Resolved, filter the queue, and delete tickets.

This adapts the [course reference](https://github.com/Nency-Ravaliya/devsecops-python)
and the existing HeroBoard with limited application changes. The React layout,
FastAPI CRUD code, database table, and chart directory are reused. Migration
`0002_helpdesk_fields` adds requester/category fields and preserves existing tasks.
The old `/api/tasks` endpoints remain compatibility aliases. The chart, release,
and Kubernetes namespace retain the name `taskboard`.

## Architecture and stack

```mermaid
flowchart LR
  Git[GitHub source] --> CI[Actions tests and frontend build]
  CI --> Docker[Docker images]
  Docker --> Trivy[Trivy security gates]
  Trivy --> GHCR[GHCR commit SHA tags]
  GHCR --> Promote[Commit desired image SHA to Git]
  Promote --> Argo[Argo CD / Helm]
  Argo --> EKS[AWS EKS]
  Browser[Browser] --> ALB[ALB Ingress]
  ALB --> Frontend[React / Nginx]
  ALB --> Backend[FastAPI]
  Frontend --> Backend
  Backend --> DB[(PostgreSQL / EBS)]
  Backend --> Prometheus --> Grafana
  Terraform[Terraform: VPC, NAT, EKS, IAM, add-ons] --> EKS
```

React/Vite, FastAPI, SQLAlchemy, PostgreSQL 16, Alembic, and Pytest form the app.
Docker, Actions, Trivy, GHCR, Terraform, EKS, Helm, Argo CD, ALB Ingress, Metrics
Server, HPA, EBS CSI, Prometheus Operator, and Grafana form the delivery stack.

## Project status and submission

The [CI pipeline](https://github.com/Sachith77/DevOps/actions/runs/38969815778)
passed 25 backend tests, the frontend build, security scans, and SHA-tagged image
publication. The AWS deployment was validated with Helm, Argo CD Synced/Healthy,
ALB ticket CRUD, both Prometheus targets UP, and live Grafana panel data.

The AWS lab was destroyed after validation (69 Terraform resources). The KMS key
is scheduled for deletion on 16 November 2026. Cloud captures require a fresh
deployment before cleanup.

The [11-slide presentation](demo/presentation.pptx) and [technical walkthrough video](demo/walkthrough.mp4) are both included directly in the `demo/` folder. The video presents the slides, then demonstrates code, CI/CD, Terraform/AWS, Argo CD, Kubernetes, Prometheus Targets UP, and populated Grafana panels.

### Evaluation Screenshots (Full 30-Artifact Rubric Proof)

All 30 verification screenshots required by the grading rubric are committed under [`demo/screenshots/`](demo/screenshots/) and [`screenshots/`](screenshots/):

| # | Artifact | Description & Rubric Evidence | Link |
|---|---|---|---|
| **01** | `01-herodesk-dashboard.png` | HeroDesk Helpdesk UI, ticket statistics, requester and category columns | [View](demo/screenshots/01-herodesk-dashboard.png) |
| **02** | `02-create-ticket.png` | Create ticket modal with synthetic requester, category, priority, description | [View](demo/screenshots/02-create-ticket.png) |
| **03** | `03-ticket-working.png` | Saved ticket transitioned to `IN_PROGRESS` / Working state and updated counters | [View](demo/screenshots/03-ticket-working.png) |
| **04** | `04-mobile-layout.png` | Mobile responsive layout (iPhone 390x844) with touch-friendly controls | [View](demo/screenshots/04-mobile-layout.png) |
| **05** | `05-swagger-api.png` | FastAPI interactive Swagger UI with all 9 REST endpoints documented | [View](demo/screenshots/05-swagger-api.png) |
| **06** | `06-postgres.png` | Local PostgreSQL queries showing persisted records and helpdesk columns | [View](demo/screenshots/06-postgres.png) |
| **07** | `07-pytest.png` | Terminal execution of `pytest -v` showing 25 passing test cases | [View](demo/screenshots/07-pytest.png) |
| **08** | `08-compose.png` | `docker compose ps` showing frontend, backend, and healthy PostgreSQL | [View](demo/screenshots/08-compose.png) |
| **09** | `09-non-root.png` | Container security check: backend running as UID 10001 and frontend as UID 101 | [View](demo/screenshots/09-non-root.png) |
| **10** | `10-git-history.png` | Git commit log showing clean commits and automated GitOps promotions | [View](demo/screenshots/10-git-history.png) |
| **11** | `11-actions-green.png` | GitHub Actions pipeline run passing test, build-scan-push, and promote jobs | [View](demo/screenshots/11-actions-green.png) |
| **12** | `12-trivy-backend.png` | Trivy container vulnerability scan report for backend image (clean gate) | [View](demo/screenshots/12-trivy-backend.png) |
| **13** | `13-trivy-frontend.png` | Trivy container vulnerability scan report for frontend image (clean gate) | [View](demo/screenshots/13-trivy-frontend.png) |
| **14** | `14-ghcr-backend.png` | GitHub Container Registry package page for backend image with commit SHA tags | [View](demo/screenshots/14-ghcr-backend.png) |
| **15** | `15-ghcr-frontend.png` | GitHub Container Registry package page for frontend image with commit SHA tags | [View](demo/screenshots/15-ghcr-frontend.png) |
| **16** | `16-terraform-plan.png` | `terraform plan` output showing 69 AWS resources to add | [View](demo/screenshots/16-terraform-plan.png) |
| **17** | `17-aws-vpc.png` | AWS Management Console VPC dashboard in Sydney (`ap-southeast-2`) | [View](demo/screenshots/17-aws-vpc.png) |
| **18** | `18-aws-eks.png` | AWS Management Console EKS cluster details showing active `herodesk-eks` | [View](demo/screenshots/18-aws-eks.png) |
| **19** | `19-kubernetes-pods.png` | `kubectl get pods -o wide` showing 2 frontends, 2 backends, and DB Running | [View](demo/screenshots/19-kubernetes-pods.png) |
| **20** | `20-services-storage-ingress.png` | ClusterIP services, bound 5Gi gp3 EBS volume, and AWS ALB Ingress hostname | [View](demo/screenshots/20-services-storage-ingress.png) |
| **21** | `21-helm-release.png` | Direct Helm deployment verification (`taskboard` release deployed) | [View](demo/screenshots/21-helm-release.png) |
| **22** | `22-argocd.png` | Argo CD UI showing `herodesk` application Synced and Healthy with resource tree | [View](demo/screenshots/22-argocd.png) |
| **23** | `23-aws-application.png` | HeroDesk application accessed through live AWS ALB public Ingress URL | [View](demo/screenshots/23-aws-application.png) |
| **24** | `24-metrics.png` | FastAPI `/metrics` Prometheus metrics endpoint with counters and histograms | [View](demo/screenshots/24-metrics.png) |
| **25** | `25-prometheus-target.png` | Prometheus Targets dashboard showing both backend pods reporting `UP` | [View](demo/screenshots/25-prometheus-target.png) |
| **26** | `26-grafana.png` | Grafana dashboard with request rate, zero errors, and latency panels | [View](demo/screenshots/26-grafana.png) |
| **27** | `27-hpa.png` | Horizontal Pod Autoscaler (HPA) targets and `kubectl top pods` metrics | [View](demo/screenshots/27-hpa.png) |
| **28** | `28-troubleshooting.png` | Kubernetes troubleshooting drill diagnosing and repairing ImagePullBackOff | [View](demo/screenshots/28-troubleshooting.png) |
| **29** | `29-terraform-destroy.png` | Terraform teardown log confirming `Resources: 69 destroyed` | [View](demo/screenshots/29-terraform-destroy.png) |
| **30** | `30-aws-cleanup.png` | AWS Management Console post-cleanup showing zero clusters and resources | [View](demo/screenshots/30-aws-cleanup.png) |

Follow the [course grading rubric](https://github.com/Nency-Ravaliya/devsecops-python/blob/main/GRADING.md)
and [submission requirements](https://github.com/Nency-Ravaliya/devsecops-python/blob/main/SUBMISSION.md)
for the required evidence. Each server or port-forward command needs its own
terminal.

## 1. Run locally in PowerShell

Start Docker Desktop in Linux container mode, then:

```powershell
Set-Location 'D:\devops-heros\session21-python'
.\scripts\preflight.ps1 -LocalOnly
docker compose up -d --build
docker compose ps
```

Open [HeroDesk](http://localhost:3000), [Swagger](http://localhost:8000/docs),
[readiness](http://localhost:8000/ready), or [metrics](http://localhost:8000/metrics).
Compose keeps existing data in the `postgres-data` volume. Its demo database
credentials are only for local use. PostgreSQL stays on the Compose network,
without publishing a Windows host port. Inspect records with:

```powershell
Set-Location 'D:\devops-heros\session21-python'
docker compose exec postgres psql -U taskboard -d taskboard -c "SELECT id, title, requester, category, status FROM tasks;"
```

Keep the stack running during tests and browser checks. To stop it afterwards, run
`docker compose down`. Only add `-v` when you intentionally want to erase records.

### Tests and frontend development

The image and CI use Python 3.12. Run tests in the image if your host Python differs:

```powershell
Set-Location 'D:\devops-heros\session21-python'
docker compose build backend
docker run --rm --mount "type=bind,source=$((Get-Location).Path)/backend,target=/app" -w /app session21-python-backend:latest pytest -v
```

For frontend development, use a separate terminal and keep the backend running:

```powershell
Set-Location 'D:\devops-heros\session21-python'
docker compose up -d postgres backend
Push-Location frontend
try { npm.cmd ci; npm.cmd run dev } finally { Pop-Location }
```

Each test uses its own in-memory SQLite database. Compose exercises real
PostgreSQL migrations. Vite proxies `/api` to port 8000. The production Nginx
container listens on 8080 and uses `BACKEND_HOST` for service discovery.

## 2. API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | /health, /ready, /metrics | Liveness, database readiness, metrics |
| GET | /api/tickets | List; optional status/category query filters |
| GET | /api/tickets/stats | Ticket counts by status |
| GET | /api/tickets/{id} | Fetch a ticket |
| POST | /api/tickets | Create a ticket |
| PUT | /api/tickets/{id} | Update a ticket |
| DELETE | /api/tickets/{id} | Delete a ticket |

Stored statuses remain `TODO`, `IN_PROGRESS`, and `DONE`. Categories are `ACCESS`,
`NETWORK`, `APPLICATION`, `HARDWARE`, and `OTHER`. Swagger documents the schemas.
The activity list displays actual ticket records instead of static deployment claims.

## 3. CI, security scans, and image promotion

The active workflow is at the repository root:
[session21-ci-cd.yml](../.github/workflows/session21-ci-cd.yml).
GitHub does not discover nested `session21-python/.github/workflows` files;
the redundant inactive copy has been removed.

Pushes to `main` and `sync-to-devops` validate Python, the locked frontend build,
Helm, and Terraform. Pull requests validate without publishing images. Push runs
then build both images, scan them with Trivy, and publish commit SHA tags to
`ghcr.io/sachith77/herodesk-backend` and `herodesk-frontend` only after both scans
pass. HIGH/CRITICAL findings with an available fix fail the job. Unfixed findings
are excluded as in the reference; this does not mean the image has no vulnerabilities.
Download the `trivy-reports` artifact to inspect results.

On `main`, repository variable `GITOPS_AUTO_DEPLOY=true` enables a bot commit to
[gitops/images.yaml](gitops/images.yaml). Argo CD reads that commit and reconciles
the chart. The promotion job requests `contents: write`; repository and organization
policies must allow that permission. Branch protection may require a PR or approved
bot credential instead. AWS keys and
kubeconfig secrets are not required in GitHub for this GitOps flow.

The initial pipeline published both images and promoted their actual commit SHA
to `gitops/images.yaml`. For a later manual promotion, run
`.\scripts\promote-images.ps1 -ImageSha <PUBLISHED_40_CHARACTER_SHA>`, then commit
and push the changed values to `main`. Automatic promotion handles normal pushes. Make
both GHCR packages public, or create a Kubernetes `ghcr-pull` registry Secret with
a read:packages token and set `imagePullSecrets: [{name: ghcr-pull}]` in chart values.
Never commit the token or Secret.

## 4. Provision AWS

Your existing AWS CLI region is **ap-southeast-2 (Sydney)**; Terraform uses the
same default. The preflight refreshes this process's PATH so tools installed from
an Administrator shell are visible. Credentials stay in your AWS configuration.

```powershell
Set-Location 'D:\devops-heros\session21-python'
cd terraform
if (-not (Test-Path terraform.tfvars)) { Copy-Item terraform.tfvars.example terraform.tfvars }
# Optional: restrict api_allowed_cidrs to your public IP /32.
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan '-out=herodesk.tfplan'
```

Before the cluster bootstrap, install the checksum-verified project-local Helm
version used in CI. This preserves your system installation:

```powershell
Set-Location 'D:\devops-heros\session21-python'
.\scripts\install-lab-tools.ps1
.\scripts\preflight.ps1
```

Review the plan before applying. It creates **paid resources**: EKS, two m7i-flex.large
workers, EBS, a NAT gateway, and networking. The application later creates an ALB.
This is not a free-tier-only stack. The initial t3.medium attempt was refused by
this account's Free Tier restrictions. AWS reports m7i-flex.large as eligible in
Sydney, so workers use that type. Eligibility does not make the whole lab free.

```powershell
Set-Location 'D:\devops-heros\session21-python\terraform'
terraform apply herodesk.tfplan
cd ..
.\scripts\bootstrap-eks.ps1 -InCluster
.\scripts\create-db-secret.ps1 -Context herodesk-eks
```

Terraform defines two AZs with public/private subnets, private workers, EKS 1.35,
CoreDNS, kube-proxy, VPC CNI, EBS CSI, Metrics Server, the EKS Pod Identity agent,
and workload IAM roles. The account organization policy denies IAM OIDC provider
creation, so EBS CSI and the ALB controller use supported EKS Pod Identity
associations with service-account-scoped roles instead of IRSA.
The bootstrap installs the ALB controller, a gp3 StorageClass, Prometheus/Grafana,
the supplied dashboard, and Argo CD. It uses an explicit EKS context to protect
your existing Minikube setup. Verify [AWS version support](https://docs.aws.amazon.com/eks/latest/userguide/kubernetes-versions.html)
before future deployments.

`-InCluster` runs the large Helm operations in a temporary installer Job beside
the Kubernetes API. This avoids the intermittent local API connection failures
observed during this lab. The installer uses a temporary administrator binding
and removes its Job, binding, and namespace after saving its log.

## 5. Deploy through Argo CD

First ensure the bootstrap completed, `herodesk-postgres` Secret exists, images
are accessible, and the desired SHA is committed to `main`. Check the repo, branch,
and monorepo path in [argocd/application.yaml](argocd/application.yaml), then:

```powershell
Set-Location 'D:\devops-heros\session21-python'
kubectl --context herodesk-eks apply -f argocd/application.yaml
.\scripts\wait-gitops.ps1 -Context herodesk-eks
kubectl --context herodesk-eks -n argocd get applications
kubectl --context herodesk-eks -n taskboard get pods,svc,ingress,hpa,pvc
kubectl --context herodesk-eks -n taskboard rollout status deployment/taskboard-backend
kubectl --context herodesk-eks -n taskboard rollout status deployment/taskboard-frontend
kubectl --context herodesk-eks -n argocd port-forward svc/argocd-server 8443:443
```

Open Argo CD at `https://localhost:8443`. In a private terminal, run
`.\scripts\show-login-passwords.ps1 -Context herodesk-eks` to retrieve the generated
Argo CD and Grafana admin passwords. Do not record or screenshot that output.
Open the ALB hostname reported by
`kubectl get ingress` for the application. No purchased domain is required.
Ingress routes `/api` to backend Service port **8000**, and `/` to frontend Service
port **80**, which targets Nginx on **8080**.

Argo CD renders Helm templates; it does not create a Helm release history. Its
evidence is Application Synced/Healthy and the generated workloads. If the grader
requires `helm list`, demonstrate direct Helm in a separate namespace with its own
database Secret. Do not let Helm and Argo CD independently manage the same resources.
For separate direct-Helm evidence, use a disposable namespace:

```powershell
Set-Location 'D:\devops-heros\session21-python'
kubectl --context herodesk-eks create namespace taskboard-helm-demo
.\scripts\create-db-secret.ps1 -Context herodesk-eks -Namespace taskboard-helm-demo
helm upgrade --install taskboard ./helm/taskboard --kube-context herodesk-eks -n taskboard-helm-demo -f ./helm/taskboard/values-prod.yaml -f ./gitops/images.yaml --set ingress.enabled=false --set monitoring.serviceMonitor.enabled=false --set hpa.enabled=false --wait --timeout 10m
helm list --kube-context herodesk-eks -n taskboard-helm-demo
```

The separate demo creates another database volume and runs two replicas of each
application component. These overrides avoid a second ALB and duplicate metrics;
the main Argo CD deployment demonstrates Ingress, monitoring, and HPA. Uninstall
the demo release and delete its namespace after collecting evidence. Back up
records before uninstalling: the database PVC is part of the chart. Keep its
Secret while its volume exists.

## 6. Monitoring and autoscaling

Production values enable the ServiceMonitor after Prometheus CRDs are installed.
[dashboard.yaml](monitoring/dashboard.yaml) supplies request rate, server error
rate, and average latency panels. Run each forward in a separate terminal:

```powershell
Set-Location 'D:\devops-heros\session21-python'
kubectl --context herodesk-eks -n monitoring port-forward svc/kube-prometheus-stack-grafana 3001:80
kubectl --context herodesk-eks -n monitoring port-forward svc/kube-prometheus-stack-prometheus 9090:9090
```

Open Grafana at `http://localhost:3001` with its generated admin Secret, and
Prometheus at `http://localhost:9090`. Confirm the backend target is **UP**.
Send traffic for a few minutes, then view **HeroDesk - Support API** in Grafana.

```powershell
Set-Location 'D:\devops-heros\session21-python'
.\scripts\load-test.ps1 -Url http://YOUR-ALB-HOSTNAME/api/tickets -Requests 1000
kubectl --context herodesk-eks top pods -n taskboard
kubectl --context herodesk-eks get hpa -n taskboard -w
```

The CPU HPA starts at two replicas. A light read workload may not trigger scaling.
Show actual CPU and replica changes; request count alone is not proof of scaling.
HPA scales Pods, not EC2 nodes.

## 7. Troubleshooting and cleanup

Use the deliberately broken manifests in `troubleshooting/` in a disposable
namespace. Run `.\scripts\troubleshooting-lab.ps1 -Context herodesk-eks` to
exercise and repair both failures without touching the application. Inspect Pod events for ImagePullBackOff, and Service selectors and
EndpointSlices for empty endpoints.

| Symptom | Check |
| --- | --- |
| ImagePullBackOff | Published SHA, GHCR package visibility or pull Secret |
| PostgreSQL Pending | gp3 class, EBS CSI add-on and IAM role |
| Frontend cannot start | BACKEND_HOST matches the backend Service |
| ALB returns 503 | Backend Service port 8000 and healthy /health |
| ServiceMonitor missing | Install Prometheus before enabling the monitor |
| HPA CPU unknown | Metrics Server and Pod resource requests |
| GitOps SHA unchanged | Repository variable, Actions permission, branch protection |

After saving evidence and backups, the cleanup script stops Argo reconciliation,
removes app Ingresses while the controller still runs, waits for app EBS volume
deletion, and destroys the Terraform lab. This erases its databases:

```powershell
Set-Location 'D:\devops-heros\session21-python'
.\scripts\cleanup-aws.ps1 -Context herodesk-eks
```

Terraform does not track controller-created ALBs or EBS volumes. Remove them while
their controllers still run to prevent orphans. Keep local state until destroy
completes. State, tfvars, plans, .env files, and credentials are excluded from Git.

## Limitations

This classroom application has no user login or role based access. Use synthetic
tickets. A lasting deployment needs authentication, TLS, backups, and database
operations appropriate to production. The single in-cluster PostgreSQL instance
is not a highly available managed database.
