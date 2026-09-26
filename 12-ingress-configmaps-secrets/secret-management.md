# Secret Management in the Real World — Vault, Cloud Providers & CI/CD

> Deep-dive companion to **Task 5** of [`Readme.md`](Readme.md).
> Everything here is the "what production actually does" version of the
> `db-secret.yaml` you applied in Task 3.

---

## Table of Contents

1. [The vulnerability: Base64 in Git](#1-the-vulnerability-base64-in-git)
2. [Why "just delete it from the repo" does not work](#2-why-just-delete-it-from-the-repo-does-not-work)
3. [The three-layer defence model](#3-the-three-layer-defence-model)
4. [External Secret Operators](#4-external-secret-operators)
5. [The vault providers](#5-the-vault-providers)
6. [Manifest patterns](#6-manifest-patterns)
7. [CI/CD integration](#7-cicd-integration)
8. [Kubernetes-native alternatives that need no vault at all](#8-kubernetes-native-alternatives-that-need-no-vault-at-all)
9. [Decision matrix](#9-decision-matrix)
10. [Checklist before you commit anything](#10-checklist-before-you-commit-anything)

---

## 1. The vulnerability: Base64 in Git

```text
  kubectl apply -f secret.yaml
        │
        ▼
  ┌──────────────────┐   Base64   ┌──────────────────┐
  │  secretpassword  │ ────────► │ c2VjcmV0cGFzc3dvcmQ= │
  └──────────────────┘            └──────────────────┘
   14 chars                        20 chars, 0 extra bits of protection
```

Anyone who can read the file can read the credential in one command:

```bash
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
git show HEAD:12-ingress-configmaps-secrets/02-secret/db-secret.yaml | grep POSTGRES_PASSWORD
```

The problem is not the encoding. The problem is **where the file lives**.

### The five compounding failures

| # | Failure | Why it is permanent |
|---|---|---|
| 1 | **History retention** | `git show <old-sha>:<path>` returns the blob forever. Deleting the file in a new commit does not touch the old object. |
| 2 | **Fork / mirror propagation** | The instant it lands on a remote, copies exist that you do not control and cannot recall. |
| 3 | **CI log leakage** | A single `kubectl get secret -o yaml` in a pipeline writes the value to a build log with a completely different audience. |
| 4 | **No rotation story** | A leaked key that is never rotated is a *permanent* key. Deleting the file is not a rotation. |
| 5 | **Blast radius** | One file in one repo usually holds credentials for *many* systems at once. |
| 6 | **Onboarding churn** | New developers clone the whole history. A secret "removed" a year ago is still in every clone on earth. |

### What a real leak looks like

```text
2021 — a team commits an AWS key inside a Dockerfile to a public repo.
        A secret-scanning bot finds it within 7 minutes.
        Result: thousands of dollars of cloud abuse before rotation.

      The lesson is not "Base64 is weak". The lesson is that
      SOURCE CONTROL IS NOT A SECRET STORE.
```

---

## 2. Why "just delete it from the repo" does not work

```bash
# The instinct:
git rm secret.yaml
git commit -m "remove secret"
git push
```

That is **not** a remediation. It is a cosmetic change. The blob is still reachable:

```bash
git log --all --full-history -- secret.yaml      # find every commit that had it
git show <sha>:secret.yaml                       # read it anyway
git filter-branch / BFG / git filter-repo         # rewrite history (see below)
```

History rewriting *does* work, but it is expensive and often impossible:

| Blocker | Consequence |
|---|---|
| The repo is already public | Assume it is compromised. **Rotate first, rewrite later.** |
| Anyone cloned before the rewrite | Their clone still has the object, forever |
| Forks exist | You cannot rewrite a fork you do not own |
| Open pull requests referencing old SHAs | Break, or leak the SHA → blob |
| CI caches, build artefacts, Docker layers | Still contain the file |
| GitHub/GitLab secret scanning alerts | Already fired; assume the value is burned |

**The correct incident response order is:**

```text
1. ROTATE the credential at the source (Vault / AWS / Azure)   ◄── do this FIRST
2. Audit who accessed it and what it was scoped to do
3. Then, optionally, purge it from history (filter-repo, force-push)
4. Add the scanner so it never happens again
```

Rotation is instant. History rewriting takes hours and is never guaranteed. If you can only do one thing, do the first one.

### Adding a scanner so it never happens again

```bash
# Local, pre-commit
brew install gitleaks            # or: winget install gitleaks
gitleaks install-pre-commit

# CI gate — runs on every push and PR
- name: Secret scan
  uses: gitleaks/gitleaks-action@v2
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

GitHub, GitLab and Bitbucket all have **built-in** secret scanning with push protection — enable it. It blocks the push *before* the object is ever created, which is the only point where the fix is cheap.

---

## 3. The three-layer defence model

Real secret management is never one mechanism. It is three independent layers, and a design is only as strong as its weakest one:

```text
┌──────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — THE STORE (authoritative, off-cluster)                    │
│  HashiCorp Vault · AWS Secrets Manager · Azure Key Vault · GCP SM    │
│  • encrypted at rest with a KMS/HSM key                              │
│  • full audit log: who read what, when                                │
│  • versioning + one-click rotation                                    │
│  • short-lived / dynamic credentials (DB creds that expire)          │
└───────────────────────────────┬──────────────────────────────────────┘
                                │  pull / push
┌───────────────────────────────▼──────────────────────────────────────┐
│  LAYER 2 — THE SYNC (in-cluster controller)                          │
│  External Secrets Operator · Vault Agent Injector · Secrets Store CSI│
│  • watches the store, writes a Kubernetes Secret                     │
│  • reconciles continuously → rotation propagates automatically       │
│  • credentials are NEVER stored in git                               │
└───────────────────────────────┬──────────────────────────────────────┘
                                │  mount / env
┌───────────────────────────────▼──────────────────────────────────────┐
│  LAYER 3 — CONSUMPTION (the workload)                                │
│  • prefer a mounted FILE over an env var (see §6)                    │
│  • short-lived tokens, not static passwords                           │
│  • never log the value; never echo it in a debug statement           │
└──────────────────────────────────────────────────────────────────────┘
```

**Why three layers and not one:**

- If the store is compromised, the sync layer limits how far a credential travels.
- If a Pod is compromised, the fact that it only ever held a **short-lived, scoped** token limits the blast radius.
- The sync layer is what makes rotation automatic — a static password needs a human to redeploy.

---

## 4. External Secret Operators

### 4a. External Secrets Operator (ESO) — the community standard

ESO is a Kubernetes operator + CRDs. You declare *where* a secret lives; ESO writes the Kubernetes Secret.

```text
  ┌───────────────────────────┐
  │ AWS Secrets Manager       │
  │  prod/yatri/db/password   │──┐
  └───────────────────────────┘  │
  ┌───────────────────────────┐  │    ┌──────────────────────────┐
  │ HashiCorp Vault           │──┼───►│ External Secrets Operator│
  │  secret/data/yatri        │  │    │  (controllers in-cluster)│
  └───────────────────────────┘  │    └────────────┬─────────────┘
  ┌───────────────────────────┐  │                 │ reconciles
  │ Azure Key Vault           │──┘                 ▼
  │  kv-campus-prod           │           ┌───────────────────┐
  └───────────────────────────┘           │ Secret (Opaque)  │
                                          │ yatri-db-secret  │
                                          └────────┬──────────┘
                                                   │ env / volume
                                                   ▼
                                            ┌─────────────┐
                                            │ Pod         │
                                            └─────────────┘
```

**The three CRDs:**

| CRD | Scope | Purpose |
|---|---|---|
| `SecretStore` / `ClusterSecretStore` | namespaced / cluster | *Connection details* — which vault, which credentials, which auth method. Holds **no** secret values itself. |
| `ExternalSecret` | namespaced | *What to fetch* — one per Kubernetes Secret you want. |
| `PushSecret` | namespaced | Reverse direction: copy a Kubernetes Secret **into** the vault. |

**Worked example — ExternalSecret:**

```yaml
# 1. How to REACH the vault (no secret values here — this is safe to commit)
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: aws-secrets-manager
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-south-1
      auth:
        # IRSA on EKS, or the WebIdentity / pod-identity token
        jwt:
          serviceAccountRef:
            name: eso-auth              # bound + short-lived by design

---
# 2. WHAT to fetch
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: yatri-db-secret
spec:
  refreshInterval: 1h                    # re-poll the vault hourly
  secretStoreRef:
    name: aws-secrets-manager
    kind: ClusterSecretStore
  target:
    name: yatri-db-secret                # the Secret the Pod already expects
    creationPolicy: Owner
  data:
    - secretKey: POSTGRES_USER          # key in the K8s Secret
      remoteRef:
        key: prod/yatri/db              # secret name in the vault
        property: username
    - secretKey: POSTGRES_PASSWORD
      remoteRef:
        key: prod/yatri/db
        property: password
```

```bash
# Install
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets -n external-secrets --create-namespace

# Verify
kubectl get externalsecrets
kubectl describe externalsecret yatri-db-secret      # check Conditions: Ready=True
```

**`ClusterSecretStore` is a genuine anti-pattern warning sign.** It is cluster-scoped and can reference *any* namespace, so anyone who can create an `ExternalSecret` in any namespace can pull secrets from the store. Prefer a namespaced `SecretStore` per team/namespace.

### 4b. HashiCorp Vault Agent Injector

An init container + sidecar run inside each Pod. It authenticates to Vault using the Pod's own service account (via Kubernetes auth), renders templates, and by default **wipes the Vault token from the filesystem** after startup.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: yatri-backend
spec:
  template:
    spec:
      serviceAccountName: vault-auth          # bound to a Vault role
      containers:
        - name: backend
          image: python:3.11-alpine
          env:
            - name: VAULT_ADDR
              value: https://vault.vault.svc:8200
            - name: POSTGRES_USER
              valueFrom:
                secretKeyRef:
                  name: vault-db-credentials
                  key: username
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "yatri-backend"
        vault.hashicorp.com/agent-inject-secret: "vault-db-credentials"
        vault.hashicorp.com/agent-inject-template: |
          {{- with secret "secret/data/yatri/db" -}}
          username: {{ .Data.data.username }}
          password: {{ .Data.data.password }}
          {{- end }}
        vault.hashicorp.com/agent-inject-file-perms: "0400"
```

**ESO vs Vault Agent Injector:**

| | External Secrets Operator | Vault Agent Injector |
|---|---|---|
| Philosophy | Central controller writes Secrets | Sidecar in **each** Pod fetches directly |
| Secret object in etcd | Yes (reconciled) | Optional — can write to a tmpfs volume only |
| Works with non-Vault stores (AWS/Azure/GCP) | **Yes** — that is its main point | No, Vault only |
| Latency on rotation | Next `refreshInterval` (or webhook-triggered) | Near-instant, sidecar re-renders |
| Operational cost | One controller, cluster-wide | One sidecar per Pod, more memory |
| Best for | Vendor-neutral, many clouds | Hard requirement that secrets never touch etcd |

### 4c. Secrets Store CSI Driver

The lightest of the three: a CSI driver mounts the secret as a **file** directly, with **no Kubernetes Secret object at all**.

```yaml
      volumes:
        - name: db-credentials
          csi:
            driver: secrets-store.csi.k8s.io
            readOnly: true
            volumeAttributes:
              secretProviderClass: yatri-db          # -> points at your vault
              objects: |
                - objectName: POSTGRES_PASSWORD      # -> file /mount/secrets/POSTGRES_PASSWORD
```

Best when you want the file to exist and the value to be as close to the workload as possible.

---

## 5. The vault providers

| Provider | Secrets | Encryption key | Auth in-cluster | Dynamic creds |
|---|---|---|---|---|
| **HashiCorp Vault** | Self-hosted or HCP | Sealed with an unseal key / auto-unseal via KMS | Kubernetes auth, AppRole, OIDC, JWT | **Yes** — issues short-lived DB creds |
| **AWS Secrets Manager** | Native | AWS KMS | IRSA / EKS Pod Identity | **Yes** — RDS, Redshift, IAM |
| **Azure Key Vault** | Native | Azure-managed HSM | Workload Identity (federated) | Limited (via AKS pod identity) |
| **GCP Secret Manager** | Native | Google-managed | Workload Identity Federation | **Yes** — Cloud SQL, GCS |
| **External Secrets Operator** | *Not a store* — a sync layer that speaks to all four | — | Inherits from the store | — |

### Dynamic credentials — the real endgame

The strongest pattern is to stop storing a password at all. The vault **mints one on demand** and revokes it when the lease expires:

```text
  STATIC SECRET (today)                    DYNAMIC CREDENTIAL (target)
  ─────────────────────                     ────────────────────────────
  one password, shared, permanent           a credential minted per request
  rotate → redeploy everything              rotate → automatic, zero redeploys
  leaked → valid until a human notices      leaked → valid for ≤ 15 minutes
  in etcd, in git, in CI logs               never stored anywhere at all
```

```bash
# Vault issuing a PostgreSQL credential, expiring in 1 hour
vault read database/creds/yatri-role -format=json
# { "lease_id":"...", "lease_duration":3600,
#   "data": { "username":"v-token-yatri-...", "password":"A1b2C3..." } }
```

The application connects with **that** credential. When the lease expires, the credential is dead — nobody has to remember to rotate anything, and there is no long-lived secret to leak in the first place.

---

## 6. Manifest patterns

### The one rule

> **A committed manifest names a Secret. It never contains a value.**
> The value is supplied at apply-time by a pipeline, a secret store, or an operator.

```yaml
# NEVER — this is a breach waiting to happen
data:
  POSTGRES_PASSWORD: c2VjcmV0cGFzc3dvcmQ=

# ALSO BAD — hand-encoding, and the trailing-newline trap of Task 4
data:
  POSTGRES_PASSWORD: $(echo -n "secretpassword" | base64)

# GOOD — declares intent, zero values
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
type: Opaque
stringData:            # plaintext, supplied at apply time, never committed
  POSTGRES_PASSWORD: ${DB_PASSWORD}       # expanded by the pipeline
```

`stringData` (vs `data`) exists precisely for this: the API server does the Base64 encoding for you, which also eliminates the trailing-newline bug from Task 4 by construction.

### Environment variable vs mounted file

| | `env` / `envFrom` | Mounted volume |
|---|---|---|
| Visible in | `kubectl exec -- env`, `/proc/1/environ`, crash dumps | File contents only |
| Updates | Frozen at pod start — needs a restart (Task 2) | **Live** — kubelet syncs the projected volume (~60 s) |
| In `kubectl describe pod` | **Yes**, in plain text | No |
| Sub-path updates | n/a | Yes, but the app must re-read the file |
| Best for | Non-critical, or when a restart is acceptable | **Anything genuinely sensitive** |

```yaml
      # PREFER THIS for real credentials
      volumeMounts:
        - name: db-credentials
          mountPath: /etc/secrets/db          # a read-only tmpfs-backed volume
          readOnly: true
      volumes:
        - name: db-credentials
          secret:
            secretName: yatri-db-secret
            defaultMode: 0400                 # owner read only
```

Kubernetes projects Secrets into a **tmpfs** volume, so the value never touches the container's writable layer and never ends up in a committed image layer. `defaultMode: 0400` keeps it unreadable to any other UID in the container.

### Other patterns worth knowing

```yaml
# 1. immutable: true — the Secret can be READ but never MODIFIED.
#    A tamper attempt is rejected outright instead of silently overwriting.
apiVersion: v1
kind: Secret
metadata:
  name: yatri-db-secret
immutable: true

# 2. Service-account token — never hand-manage these
apiVersion: v1
kind: ServiceAccount
metadata:
  name: yatri-backend
automountServiceAccountToken: true   # since v1.24 the token is short-lived & bound

# 3. imagePullSecrets — a Secret consumed by kubelet, not by your app
apiVersion: v1
kind: Secret
metadata:
  name: registry-creds
  annotations:
    kubernetes.io/dockerconfigjson: '{"auths":{...}}'   # generated, not typed by hand
type: kubernetes.io/dockerconfigjson
```

---

## 7. CI/CD integration

The pipeline is the only place the plaintext should exist, and even there it should exist **in memory only**.

### GitHub Actions

```yaml
name: deploy
on:
  push: { branches: [main] }

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4

      # Secrets come from repo Settings > Secrets and variables > Actions.
      # They are encrypted at rest, masked in logs, and NOT in the YAML.
      - name: Inject the Secret, then restart consumers
        env:
          DB_USER: ${{ secrets.POSTGRES_USER }}
          DB_PASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
        run: |
          kubectl create secret generic yatri-db-secret \
            --from-literal=POSTGRES_USER="$DB_USER" \
            --from-literal=POSTGRES_PASSWORD="$DB_PASSWORD" \
            --from-literal=POSTGRES_DB="${{ vars.POSTGRES_DB }}" \
            --dry-run=client -o yaml | kubectl apply -f -
          kubectl rollout restart deployment/yatri-backend
          kubectl rollout status deployment/yatri-backend --timeout=120s

      - name: Fail the build if a credential was committed
        uses: gitleaks/gitleaks-action@v2
```

### Azure DevOps — Key Vault–backed Variable Group

```yaml
# azure-pipelines.yml
variables:
- group: kv-campus-prod        # a Variable Group backed by Azure Key Vault
  # accessed as  $(dbPassword)  — the value is fetched at run time,
  # stored encrypted in Key Vault, and never printed in the log.

steps:
- script: |
    kubectl create secret generic yatri-db-secret \
      --from-literal=POSTGRES_PASSWORD="$(dbPassword)" \
      --dry-run=client -o yaml | kubectl apply -f -
  displayName: Create Secret from Key Vault
  env:
    dbPassword: $(dbPassword)
```

**Note the ordering:** the value is passed through the **environment**, never interpolated into the `script:` block as a literal. Otherwise it is baked into the command line, shows up in `set -x` output, and lands in the build log.

### The rules that matter

| Rule | Why |
|---|---|
| Never echo a secret, even in a debug branch | Build logs have a far wider audience than the repo |
| Prefer `env:` + `"$VAR"` over string interpolation | Interpolated values are visible in the rendered command |
| Mark logs `set +x` around secret handling | Belt and braces against shell tracing |
| Use OIDC / workload identity, not long-lived cloud keys | The CI runner never holds a static cloud credential |
| Rotate on a schedule *and* on every personnel change | Access changes are the most common leak trigger |
| Scope every credential to the minimum | A DB read-only user in staging; no `*` IAM actions |
| Run `gitleaks detect` as a required CI check | The last line of defence, and the cheapest one |

---

## 8. Kubernetes-native alternatives that need no vault at all

Not everything needs Vault. These are built in and often the right answer:

| Mechanism | What it removes | Available since |
|---|---|---|
| **Bound service account tokens** | Long-lived per-ServiceAccount `Secret` objects — the API server mints short-lived tokens on demand | v1.24 (graduated) |
| **`TokenRequest` API** | Any need to pre-create token Secrets at all | v1.12 |
| **`immutable: true` Secrets** | Tampering: the value can be read but never overwritten | v1.21 |
| **CSI ephemeral volumes** | Storage credentials in a Secret — kubelet requests a short-lived volume | v1.25 |
| **`kubectl create token`** | Manual token handling for debugging | v1.24 |

```bash
# A short-lived token, valid 10 minutes, scoped to one ServiceAccount.
# No Secret object is ever created.
kubectl create token yatri-backend --duration=10m
```

This is the most underrated answer in the whole topic: **the most common "secret" in a cluster is a service account token, and modern Kubernetes already refuses to store it for you.**

---

## 9. Decision matrix

| Situation | Use |
|---|---|
| Student lab, throwaway cluster | `kubectl create secret --from-literal` — and never commit it |
| Small team, cloud-native, 5–20 services | Cloud secret manager + **ESO** |
| Hard requirement that secrets never touch etcd | **Vault Agent Injector** or **Secrets Store CSI Driver** |
| Need automatic, zero-touch credential rotation | **Dynamic credentials** from Vault / AWS / GCP |
| CI/CD must deploy without a vault | GitHub Actions secrets / ADO Variable Groups + inject at apply-time |
| Only a service account token is involved | **Bound token** — no secret store at all |
| Certificate management | **cert-manager** (ACME/Let's Encrypt), TLS stored in a Secret, rotated automatically |

---

## 10. Checklist before you commit anything

```text
[ ] Is this value a credential (password, token, key, cert, connection string)?
[ ]   NO  -> commit it.
[ ]   YES -> continue.

[ ] Can it be obtained at apply-time from a secret store or pipeline variable?
[ ]   NO  -> add a secret store, or accept and document the risk.
[ ]   YES -> replace the value with a reference and inject at deploy time.

[ ] .gitignore covers the local credential file?  (*.key, *.pem, *.env, .envrc)
[ ] Will a scanner block a future commit?        (gitleaks pre-commit + CI gate)
[ ] Is the credential scoped to the minimum and short-lived where possible?
[ ] If a secret was EVER committed: rotated at the source, audited, THEN purged.
```

And the one-line version:

> **If a value would hurt if it leaked, it does not belong in a file that
> every clone of the repo will contain forever. Move it to a store, reference
> it by name, and rotate it on a schedule anyway.**
