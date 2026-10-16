# Evidence index

These are real command/API results. Account IDs are redacted. Logs do not replace
the screenshots or narrated video required by the rubric. Cloud checks ran on
16 October UTC / 17 October 2026 IST.

- `cloud-api-and-grafana.txt`: public ALB frontend/API checks, both Prometheus
  targets UP, authenticated Grafana datasource and three live panel query values.
- `cloud-argocd.txt`, `cloud-argocd-rollout.txt`: Synced/Healthy Git revision and
  successful application rollouts.
- `cloud-workloads.txt`, `cloud-deployment-images.txt`, `cloud-nodes.txt`,
  `cloud-cpu.txt`, `cloud-service-monitor.txt`: ready workloads, published SHA tags,
  worker nodes, actual CPU readings, and application metrics discovery.
- `cloud-helm.txt`, `cloud-helm-demo.txt`, `cloud-bootstrap.txt`: deployed direct
  Helm application and infrastructure chart releases.
- `cloud-troubleshooting.txt`: bad image and Service failures diagnosed/repaired;
  diagnostic namespace removed.
- `github-actions-bootstrap.json`: successful workflow for the deployed image SHA
  `0623f167c0c6eb954176d9065e3218d7e4324d15`. `trivy/` contains that run's actual
  scan reports. The policy excludes unfixed findings.
- `github-actions-final.json`: successful later script-fix workflow for
  `b21a790fd3d04571757db77036f01f08f66d79bb`; its images were also verified publicly
  pullable. That later SHA was not redeployed during teardown.
- `terraform-pod-identity-apply.txt`, `terraform-metrics-network-apply.txt`: the
  successful account-specific IAM and Metrics Server network repairs.
- `terraform-apply.txt`, `terraform-recovery-apply.txt`: historical interrupted or
  failed attempts, retained to document instance eligibility and OIDC restrictions.
  They are not proof of successful deployment.
- `aws-cleanup-recovery.txt`: one worker's termination lifecycle was allowed to
  continue only after confirming a deleting node group, zero desired workers, and
  no application EBS volumes.
- `terraform-destroy.txt`, `aws-cleanup-verification.json`: successful destruction
  and post-cleanup resource checks. The KMS key follows its scheduled deletion
  window; its state and date are recorded.
- `local-*.txt`, `helm-lint.txt`, `terraform-validate.txt`, `git-history.txt`:
  local engineering evidence, including 25 tests and the 1,000-request local load
  script. HPA scale-out was not observed in the cloud run.

See [VALIDATION.md](../../session21-python/VALIDATION.md) for the final cleanup
result and the distinction between verified behavior and missing manual artifacts.
