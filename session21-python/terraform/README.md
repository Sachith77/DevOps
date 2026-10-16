# HeroDesk AWS infrastructure

Follow [the project setup](../README.md#4-provision-aws) from PowerShell. Credentials
come from your existing AWS CLI profile or environment. Never add keys to HCL,
tfvars, or Git.

Defaults: Sydney (`ap-southeast-2`), `herodesk-eks`, EKS 1.35, two private t3.medium
workers, two public/private subnet pairs, and one NAT gateway. EBS CSI and Metrics
Server add-ons and workload IAM roles support persistence, HPA, and ALB routing.
The controller IAM policy is pinned to upstream v2.14.1 / Helm chart 1.14.0.

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan '-out=herodesk.tfplan'
# Review the plan and AWS charges first.
terraform apply herodesk.tfplan
```

Commit `.terraform.lock.hcl`. Retain local state for this individual lab; never
lose or commit it. For a team, configure encrypted remote state with locking
before provisioning.

Before `terraform destroy`, stop Argo CD and remove the app Ingress and PVC while
the Kubernetes controllers still run. See the project README for cleanup.
