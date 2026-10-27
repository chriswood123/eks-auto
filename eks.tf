# Optional: lock down the public API endpoint to the runner's own public IP.
# ipv4.icanhazip.com forces an IPv4 result (EKS expects IPv4 CIDRs).
data "http" "local_ip" {
  count = var.restrict_api_to_local_ip ? 1 : 0

  url = "https://ipv4.icanhazip.com"
}

locals {
  public_access_cidrs = var.restrict_api_to_local_ip ? ["${chomp(data.http.local_ip[0].response_body)}/32"] : var.public_access_cidrs
}

resource "aws_eks_cluster" "this" {
  name     = var.name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  # Required for Auto Mode: EKS manages the core addons instead.
  bootstrap_self_managed_addons = false

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  # STANDARD avoids the extended-support price premium ($0.60/hr).
  upgrade_policy {
    support_type = "STANDARD"
  }

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    endpoint_public_access  = true
    endpoint_private_access = true
    public_access_cidrs     = local.public_access_cidrs
  }

  tags = var.tags

  # Ensure IAM permissions exist before cluster creation and are removed
  # only after cluster deletion, so EKS can manage its EC2 infrastructure.
  depends_on = [
    aws_iam_role_policy_attachment.cluster,
    aws_iam_role_policy_attachment.node,
  ]
}
