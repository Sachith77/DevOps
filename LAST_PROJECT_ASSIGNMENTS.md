# Project Assignments & Repository State Summary

> **Document Purpose:** Handover and quick-reference guide for AI assistants and contributors across chat sessions. Summarizes all completed DevOps assignments, folder structures, git branches, reference repository connections, and standard conventions.

---

## 1. Repository & Git Configuration

* **Working Workspace Directory:** `d:\devops-heros`
* **Current Active Branch:** `sync-to-devops` (in sync with `origin/main`)
* **Primary Git Remote (`origin`):**
  * `https://github.com/Sachith77/DevOps.git`
* **Reference Remote (`reference`):**
  * Repository: `https://github.com/Nency-Ravaliya/devops-heros.git`
  * Added as remote `reference`, fetched branch: `reference/main`
  * Local SSL verification setting: `http.sslVerify = false` (configured to prevent Windows schannel cert errors)
  * Access reference files anytime with: `git show reference/main:<path>` or `git ls-tree reference/main:<folder>`

---

## 2. Completed Assignments Inventory (Sessions 01 – 12)

### Season 1: Fundamentals (Sessions 01 – 08)
* **`01-linux-fundamentals/`**:
  * `task1-soft-vs-hard-links.md`: Soft links vs. hard links (inodes, deletions, cross-device).
  * `task2-adduser-vs-useradd.md`: Low-level `useradd` vs. high-level Debian/Ubuntu `adduser`.
  * `task3-journalctl.md`: Systemd journal navigation, boot filtering, service logging.
  * `task4-cheat-sheet-practice.md`: Everyday sysadmin commands.
* **`02-shell-scripting/`**:
  * `README.md` & automation bash scripts (loops, conditions, log parsers, system monitors).
* **`03-networking-fundamentals/`**:
  * `networking-commands.md`: `netstat`, `ss`, `ip`, `traceroute`, `dig`, DNS records, OSI layers.
* **`04-git-github/`**:
  * `git-cherry-pick.md`: Cherry picking commits across branches.
  * `git-commit-a-vs-m.md`: Flags distinction, staging flow, untracked vs tracked files.
* **`05-docker-fundamentals/`**:
  * Core container engine concepts, images, layers, container lifecycle.
* **`06-dockerfiles-multistage/`**:
  * `SUBMISSION.md`: Multi-stage build optimization, image size reduction, production artifact isolation.
* **`07-docker-network/`**:
  * `README.md`: Docker bridge, host, none networks, container-to-container communication.
* **`08-docker-networking-volume/`**:
  * `README.md`: Volume mounts, bind mounts, data persistence across container restarts.

---

### Season 2: Kubernetes Deep Dive (Sessions 09 – 12)
*All tasks outlined in `DevOps Assignment Season 2.md` have been fully implemented, documented, and verified.*

#### 1. `09-kubernetes-fundamentals/`
* **`Readme.md`**:
  * Task 1: Minikube & kubectl version verification (`minikube version: v1.39.0`, `kubectl client: v1.34.1`).
  * Task 2: Cluster lifecycle (`minikube start`, `minikube status`, `minikube stop`).
  * Task 3: In-depth Kubernetes Architecture documentation (API Server, etcd, Controller Manager, Kubelet, Kube-proxy, Container Runtime).
  * Full terminal outputs and screenshot assets in `./screenshots/`.

#### 2. `10-kubernetes-pods-replicasets-deployments/`
* **`Readme.md` & Manifests**:
  * Pods: `pod.yml`, multi-container pods, pod lifecycles, and status phases.
  * ReplicaSets: `replicaset.yml`, label selectors, replica reconciliation, self-healing.
  * Deployments: `deployment.yml`, rolling updates, rollbacks (`kubectl rollout undo`), strategy comparisons (Canary, Blue-Green, Recreate).
  * Subdirectories: `01-rolling-update/`, `02-blue-green/`, `03-canary/`, `04-recreate/`, `daemonset/`, `pod-lifecycle/`, `troubleshooting/`.

#### 3. `11-kubernetes-networking-services/`
* **`Readme.md`**, `service.md`, `fqdn.md`:
  * Service Types:
    * `01-clusterip/`: Internal service discovery and iptables/kube-proxy routing.
    * `02-nodeport/`: Exposing services on node port range 30000–32767.
    * `03-loadbalancer/`: Cloud load balancer simulation with Minikube tunnel.
    * `04-externalname/`: External CNAME DNS redirection.
    * `05-headless/`: Headless services (`clusterIP: None`) for stateful workloads.
  * DNS & Endpoints: CoreDNS resolution tests, FQDN discovery, Endpoints slices, troubleshooting guides.

#### 4. `12-ingress-configmaps-secrets/`
* **`Readme.md`**, `secret-management.md`:
  * `01-configmap/`: Injecting environment variables and mounting config files from ConfigMaps.
  * `02-secret/`: Base64 encoded secrets, volume mount security, key hygiene (`.gitignore` enforcement for `*.key`, `*.pem`).
  * `03-ingress/`: NGINX Ingress Controller setup (`minikube addons enable ingress`), path-based & host-based routing.
  * `04-full-demo/`: End-to-end TLS-secured microservice demo (`tls.crt`, `tls.key`), host file mapping (`local.devops.internal`).
  * Includes resolved troubleshooting notes for local port collision workarounds.

---

## 3. Submission & Documentation Standards

When implementing future sessions, maintain the established repository quality standards:
1. **Directory Structure**:
   * Session directory format: `XX-<topic-name>/` (e.g., `13-storage-hpa-probes/`).
   * Sub-task directories for YAML manifests: `01-.../`, `02-.../`, etc.
   * Screenshots directory: `./screenshots/` with numbered filenames (`01-...png`, `02-...png`).
2. **README Structure**:
   * Clear front-matter header (Author, Course, Session, Repository).
   * For every task:
     * One-line objective description.
     * Exact CLI command(s).
     * Complete terminal output block (in ` ```text `).
     * Markdown screenshot embed: `![Description](./screenshots/xx-filename.png)`.
     * YAML manifest explanations where applicable.
3. **Security Standards**:
   * Never commit unencrypted private keys or `.pem`/`.key` files (enforced by `.gitignore`).

---

## 4. Upcoming Sessions in Reference Repository (`reference/main`)

The reference repository (`https://github.com/Nency-Ravaliya/devops-heros`) contains the syllabus materials for upcoming assignments:
* **Session 13**: `session-13-storage-hpa-probes`
  * Volumes (`emptyDir`, `hostPath`), PV, PVC, StorageClass
  * Horizontal Pod Autoscaler (HPA), metrics-server, load generation
  * Probes (Liveness, Readiness, Startup)
  * Mini-project integration
* **Session 14**: `session-14-kubernetes-troubleshooting`
  * Pod crash loops (`CrashLoopBackOff`), image pull errors, pending states, node debugging
* **Session 15**: `session-15-helm`
  * Helm charts, templating, values, release management
* **Session 16**: `session-16-github-actions`
  * CI/CD pipelines, workflows, automated testing, Docker build & push
* **Session 17**: `session-17-devsecops`
  * Security scanning, Trivy, SonarQube, secret scanning
* **Session 18 & 19**: `session18-terraform-iac` & `session19-cloud-terraform`
  * Infrastructure as Code, AWS / cloud provisioning, Terraform state & modules
* **Session 20**: `session20-monitoring-observability-gitops`
  * Prometheus, Grafana, ArgoCD, GitOps workflows
* **Session 21**: `session21-python`
  * DevOps automation scripts with Python

---

## 5. Quick Pick-Up Instructions for New Chat

When opening a new chat to continue:
1. Note that **Sessions 01 through 12 are 100% completed**.
2. Run `git status` to verify working branch `sync-to-devops`.
3. Check reference files directly from the fetched remote using:
   ```bash
   git ls-tree reference/main:<session-folder>
   git show reference/main:<session-folder>/<file>
   ```
4. Read the shared task requirements from the user and generate matching folder structures, YAML manifests, execution logs, and detailed `Readme.md` documentation following the standard established above.
