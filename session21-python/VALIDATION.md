# Validation record - 17 October 2026 (IST)

This records observed results, not a self-awarded grade. Cloud checks ran on
16 October UTC / 17 October IST. The user requested AWS destruction after
validation. Logs are saved in [demo/evidence](../demo/evidence).

| Rubric area | Observed result | Remaining submission evidence |
| --- | --- | --- |
| M1 Application | Local PostgreSQL-backed CRUD and ALB-backed ticket create/read/update/filter/delete passed; frontend returned HTTP 200 | Browser and responsive-layout screenshots; visual UI walkthrough |
| M2 Testing | 25 isolated SQLite tests passed locally and in GitHub Actions | Test output screenshot |
| M3 Git/GitHub | Public Sachith77/DevOps repository; meaningful commit history and ignore rules | Commit history screenshot and submission form |
| M4 Docker | Both images built; Compose running; backend UID 10001 and frontend UID 101; PostgreSQL healthy | Compose, non-root, and browser screenshots |
| M5 CI/CD | Real Actions run passed tests/build/scan/push/promotion; public GHCR images use commit SHA tags | Actions and registry screenshots |
| M6 Security | Trivy gate passed for both images with zero fixable HIGH/CRITICAL findings | Scan screenshots; reports retained in evidence/trivy |
| M7 Terraform | VPC with two public and two private subnets, NAT, EKS, managed node group and add-ons provisioned; two workers Ready | AWS Console, plan, and destruction screenshots |
| M8 Kubernetes/Helm | Direct Helm release deployed; main Argo application Synced/Healthy; two ready backend and two ready frontend Pods; ClusterIP Services; gp3 PVC Bound; public ALB API verified | Helm, Argo, Kubernetes and Ingress browser screenshots |
| M9 Observability | Both backend Prometheus targets UP; authenticated Grafana API loaded all three dashboard panels and returned live values through its Prometheus datasource | Prometheus Targets and populated Grafana browser screenshots |
| M10 Presentation/docs | Root README and project runbook supplied; editable 11-slide presentation committed | Mandatory real narrated video and manual screenshots are still missing |

The successfully deployed images were tagged
`0623f167c0c6eb954176d9065e3218d7e4324d15`. Their complete
[Actions run](https://github.com/Sachith77/DevOps/actions/runs/38968758149)
succeeded, including the GitOps promotion job. The live Application reconciled
the resulting bot commit `4276d5738c483465ba6d69360865508aa6733e67`.
A later command-helper fix passed the complete
[final workflow](https://github.com/Sachith77/DevOps/actions/runs/38969815778).
Its public images are tagged `b21a790fd3d04571757db77036f01f08f66d79bb` and were
promoted by bot commit `56a99a3`. Those later tags were not redeployed during
teardown. Consult gitops/images.yaml when redeploying.

## Local and static checks

- Frontend production build and npm audit passed; a dependency lockfile is present.
- Alembic migrated the existing database from 0001 to 0002 while preserving four
  existing records. Readiness and the frontend API proxy passed again after
  restarting the local stack on 17 October.
- Helm strict lint, production rendering, Terraform init/validate/plan, actionlint
  with shellcheck, and PowerShell syntax parsing passed.
- The common PowerShell helper was exercised with kubectl `-o`, comma-separated
  resource lists, Helm, Terraform, and Docker. It checks native exit codes and
  tolerates informational stderr in Windows PowerShell 5.1.
- The presentation was rendered and visually reviewed. This is separate from a
  visual review of the running application, which was not available.
- The local load-test script completed 1,000 requests. All 24 PowerShell blocks
  across the project and root README parsed successfully. A targeted Git history
  check found no AWS key IDs, GitHub tokens, or private-key headers in added lines.

Trivy excludes unfixed findings, matching the reference gate. An unrestricted
scan found unfixed OS vulnerabilities; a passing gate does not mean an image is
free of all vulnerabilities. There is one non-failing Starlette/httpx test-client
deprecation warning.

## Real cloud checks and repairs

- Two `m7i-flex.large` private workers ran in Sydney (`ap-southeast-2`). The initial
  `t3.medium` attempt was refused by this account's instance eligibility rules;
  the failed, empty node group was removed.
- The organization denies IAM OIDC provider creation. Workload roles use EKS Pod
  Identity, with trust scoped to the required service accounts. No organization
  policy was changed. EBS CSI provisioned real application volumes successfully.
- Added control-plane access to Metrics Server TCP 10251 from the cluster security
  group. Its API became Available, HPA CPU became readable, and namespace cleanup
  worked. HPA stayed at two replicas during validation; scale-out was not observed.
- Large Helm operations ran in a temporary in-cluster Job after intermittent
  workstation API failures. Its Job, namespace, and administrator binding were
  removed. Monitoring, Argo CD, and ALB controller Helm releases were deployed.
- The ALB frontend returned HTTP 200; API create/read/update/status-and-category
  filtering/delete/404 checks passed through the public Ingress. The synthetic
  verification ticket was deleted.
- Prometheus scraped both backend replicas. Grafana authenticated successfully,
  its datasource health was OK, and all three panels returned live data: requests
  approximately 0.711/s, errors 0/s, average duration approximately 0.001669s at the
  recorded sample. These values are samples, not load-test performance guarantees.
- The isolated troubleshooting exercise demonstrated an image pull failure,
  repaired the image, diagnosed an empty Service EndpointSlice, and repaired its
  selector and target port. The diagnostic namespace was deleted.

## Cleanup and remaining work

Terraform destruction completed successfully: **69 resources destroyed**. EKS
lists no clusters in Sydney. The lab KMS key is `PendingDeletion`, scheduled for
16 November 2026 under AWS's deletion window. Final resource checks are saved in
`demo/evidence/aws-cleanup-verification.json`; destruction output is in
`demo/evidence/terraform-destroy.txt`. One worker's termination
lifecycle was allowed to continue after confirming zero desired workers and no
application EBS volumes. Local Compose data is retained.

Browser automation had no connected browser or application session. No new UI,
AWS Console, Argo, Prometheus, or Grafana screenshot is claimed. Use
[SCREENSHOTS.md](../demo/SCREENSHOTS.md) for the complete 30-capture checklist.
Command logs are useful evidence but do not replace required screenshots.

The rubric also requires a real narrated video presenting the slides and a live
walkthrough. No video has been created. After AWS cleanup, cloud screenshots and
the live video require a fresh deployment and capture before its teardown.
This submission is not complete until those manual artifacts are added.

AWS credentials, generated passwords, Terraform state and plans, and local tool
files remain outside version control. The pre-migration PostgreSQL backup remains
outside the repository at `%TEMP%/herodesk-before-migration.sql`.
