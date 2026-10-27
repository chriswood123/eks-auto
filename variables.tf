variable "name" {
  description = "Name of the EKS cluster. Also used as a prefix for VPC and IAM resources."
  type        = string
  default     = "eks-auto"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster. Keep this on a version in standard support to avoid extended-support charges."
  type        = string
  default     = "1.37"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint. Restrict to your own IP for better security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
