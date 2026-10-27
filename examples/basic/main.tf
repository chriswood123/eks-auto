# eu-north-1 (Stockholm): cheapest and lowest-carbon AWS region in Europe.
variable "region" {
  type    = string
  default = "eu-north-1"
}

provider "aws" {
  region = var.region
}

module "eks_auto" {
  source = "../.."

  name                     = "eks-auto"
  restrict_api_to_local_ip = true
}

output "cluster_endpoint" {
  value = module.eks_auto.cluster_endpoint
}

output "kubeconfig_command" {
  value = module.eks_auto.kubeconfig_command
}
