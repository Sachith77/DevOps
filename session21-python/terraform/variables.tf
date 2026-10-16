variable "aws_region" {
  description = "AWS region. Matches the configured local AWS CLI region."
  type        = string
  default     = "ap-southeast-2"
}

variable "cluster_name" {
  type    = string
  default = "herodesk-eks"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "worker_instance_types" {
  description = "x86_64 worker types. m7i-flex.large is eligible under this account's Free Tier restrictions and provides 8 GiB for monitoring/GitOps. This does not make EKS/NAT free."
  type        = list(string)
  default     = ["m7i-flex.large"]
}

variable "kubernetes_version" {
  description = "EKS version; verify standard support before creating the cluster."
  type        = string
  default     = "1.35"
}

variable "api_allowed_cidrs" {
  description = "Public Kubernetes API access. Restrict to your public IP /32 where possible."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
