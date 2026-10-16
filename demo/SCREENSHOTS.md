# Screenshots to take for the HeroDesk submission

Save real captures under `demo/screenshots/` with the names below. A saved log is
useful evidence but does not replace a screenshot when the rubric asks for one.
Use synthetic tickets. Never capture access keys, tokens, generated passwords,
Secret YAML, browser credential popups, or a terminal running show-login-passwords.ps1.

## Local application and engineering

| File | Open/run | What must be visible |
| --- | --- | --- |
| 01-herodesk-dashboard.png | http://localhost:3000 | HeroDesk branding, populated tickets, requester/category, statistics |
| 02-create-ticket.png | New ticket form | Synthetic requester, category, priority, description |
| 03-ticket-working.png | Create a ticket, click Next | Saved ticket marked Working and updated counters |
| 04-mobile-layout.png | Browser device emulation, 390 px wide | Usable responsive page and ticket controls |
| 05-swagger-api.png | http://localhost:8000/docs | Ticket GET/POST/PUT/DELETE routes and successful request |
| 06-postgres.png | docker compose exec postgres psql -U taskboard -d taskboard -c "SELECT id,title,requester,category,status FROM tasks;" | Real rows and helpdesk columns |
| 07-pytest.png | Run the test command from README | 25 passed and test names |
| 08-compose.png | docker compose ps | All three services running; PostgreSQL healthy |
| 09-non-root.png | docker compose exec backend id; docker compose exec frontend id | Backend UID 10001 and frontend UID 101 |
| 10-git-history.png | git log --oneline -12 | Meaningful history and the new implementation commit |

## GitHub delivery and security

| File | Open/run | What must be visible |
| --- | --- | --- |
| 11-actions-green.png | GitHub > Actions > latest HeroDesk run | Test and build-scan-push jobs successful, source SHA |
| 12-trivy-backend.png | Backend scan job/report artifact | Image identity, HIGH/CRITICAL scan policy, result |
| 13-trivy-frontend.png | Frontend scan job/report artifact | Frontend identity and scan result |
| 14-ghcr-backend.png | GitHub Packages > herodesk-backend | Published commit SHA tag |
| 15-ghcr-frontend.png | GitHub Packages > herodesk-frontend | Matching commit SHA tag |

## AWS, Kubernetes, and observability (capture before teardown)

All Kubernetes commands below use `--context herodesk-eks`. Select Sydney
`ap-southeast-2` in the AWS Console. After automatic cleanup these live screens
will no longer exist; saved evidence logs remain in `demo/evidence/`.

| File | Open/run | What must be visible |
| --- | --- | --- |
| 16-terraform-plan.png | terraform plan from session21-python/terraform | Non-empty resource summary, no errors |
| 17-aws-vpc.png | AWS Console > VPC | herodesk VPC and two public/private subnet pairs |
| 18-aws-eks.png | AWS Console > EKS > herodesk-eks | Active cluster and managed node group |
| 19-kubernetes-pods.png | kubectl --context herodesk-eks -n taskboard get pods -o wide | Two frontend and at least two backend Pods Running/Ready, PostgreSQL Ready |
| 20-services-storage-ingress.png | kubectl --context herodesk-eks -n taskboard get svc,pvc,ingress | ClusterIP services, Bound PVC, ALB hostname |
| 21-helm-release.png | helm list --kube-context herodesk-eks -n taskboard-helm-demo | Direct Helm demo release deployed |
| 22-argocd.png | https://localhost:8443 after port forwarding | herodesk Synced and Healthy, desired Git revision |
| 23-aws-application.png | ALB hostname in browser | HeroDesk works through AWS Ingress, not localhost |
| 24-metrics.png | kubectl --context herodesk-eks -n taskboard port-forward svc/taskboard-backend 8001:8000; then open localhost:8001/metrics | Prometheus-formatted application metrics |
| 25-prometheus-target.png | http://localhost:9090/targets | taskboard backend target UP |
| 26-grafana.png | http://localhost:3001 > HeroDesk - Support API | Populated live request/latency panels and time range |
| 27-hpa.png | kubectl --context herodesk-eks -n taskboard get hpa; kubectl --context herodesk-eks -n taskboard top pods | CPU readings and current/desired replicas; only claim scaling if observed |
| 28-troubleshooting.png | Broken workload in herodesk-lab | ImagePullBackOff diagnosis or empty EndpointSlice investigation and repair |
| 29-terraform-destroy.png | Cleanup output | Destroy complete and resource count |
| 30-aws-cleanup.png | AWS EKS/VPC/EC2 after cleanup | Lab cluster, NAT, ALB, app volumes, and worker instances removed |

## Recording

Record a narrated walkthrough beginning with `demo/presentation.pptx`, then the
code, successful pipeline, registry images, Terraform/AWS, Argo CD, Kubernetes,
Prometheus, and Grafana. Capture live cloud evidence before teardown. Save the
video as `demo/walkthrough.mp4`, or upload it as a GitHub release asset and put
the release link in `demo/README.md`. The video must show the actual project;
slides, logs, or an automated silent clip alone do not satisfy the walkthrough.
