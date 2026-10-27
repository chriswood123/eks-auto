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

variable "az_count" {
  description = "Number of availability zones (and public subnets) to spread across. EKS requires at least 2. Capped by the number of AZs available in the region."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "EKS requires subnets in at least 2 availability zones."
  }
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API endpoint. Ignored when restrict_api_to_local_ip is true."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "restrict_api_to_local_ip" {
  description = "When true, public_access_cidrs is set to the public IP of the machine running plan/apply (looked up via icanhazip.com)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
