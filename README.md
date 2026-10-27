# eks-auto

Minimal [OpenTofu](https://opentofu.org/) module for an [Amazon EKS Auto Mode](https://docs.aws.amazon.com/eks/latest/userguide/automode.html) cluster, optimised for low monthly cost.

## Usage

The module is at the repo root; `examples/basic` is a ready-to-apply root configuration. A Makefile wraps the workflow:

```sh
make init        # install providers (examples/basic)
make plan        # preview changes
make apply       # create the cluster (~15-20 min)
make kubeconfig  # configure kubectl
make destroy     # tear everything down
```

Prerequisites: `tofu`, `aws` CLI with credentials, and `kubectl` (to use the cluster).

Use it as a module in your own configuration:

```hcl
module "eks_auto" {
  source = "github.com/chriswood123/eks-auto"

  name               = "eks-auto"
  kubernetes_version = "1.35"
}
```

The module is region-agnostic; it deploys wherever the caller's AWS provider points.

## Cost design

| Decision | Saving |
|---|---|
| Public subnets only, no NAT Gateway | ~$32/month + data processing charges |
| No control-plane CloudWatch logs | CloudWatch log ingestion/storage |
| No self-managed add-ons (`bootstrap_self_managed_addons = false`) | Auto Mode manages CoreDNS, kube-proxy, VPC CNI at no extra charge |
| `STANDARD` support policy + pinned Kubernetes version | Avoids the $0.60/hr extended-support premium |
| Auto Mode `general-purpose` pool | Scales to zero nodes when nothing is deployed |

The `system` node pool keeps roughly one small node running for critical addons. Built-in pools use on-demand instances; Auto Mode bills a management premium on top of instance hours.

**Expected idle cost: ~$85–95/month** — the EKS control plane alone is a fixed ~$73/month ($0.10/hr) and cannot be avoided. Load balancers and EBS volumes are billed only if your workloads create them.

### Region

The example defaults to **eu-north-1 (Stockholm)**: the cheapest AWS region in Europe (~5% below Ireland on compute) and one of the lowest-carbon (Nordic hydro/wind grid, on AWS's carbon-free-energy region list).

### Not included, deliberately

- **Spot capacity** — would cut node costs by ~60–70%, but Auto Mode only supports it via a custom Karpenter `NodePool` applied with the Kubernetes provider, which complicates the module. A reasonable follow-up.
- **IRSA / OIDC provider** — Auto Mode includes EKS Pod Identity, which covers most AWS-access use cases without an OIDC provider.
- **VPC endpoints, private-only API endpoint** — extra cost/complexity.

## Inputs

| Name | Description | Default |
|---|---|---|
| `name` | Cluster name, also prefixes VPC/IAM resources | `eks-auto` |
| `kubernetes_version` | Keep on a standard-support version | `1.35` |
| `vpc_cidr` | CIDR for the dedicated VPC | `10.0.0.0/16` |
| `public_access_cidrs` | CIDRs allowed to reach the public API endpoint (ignored when `restrict_api_to_local_ip` is true) | `["0.0.0.0/0"]` |
| `restrict_api_to_local_ip` | Restrict API access to the public IP of the machine running plan/apply (looked up via icanhazip.com) | `false` |
| `tags` | Tags applied to all resources | `{}` |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | EKS cluster name |
| `cluster_endpoint` | Kubernetes API server endpoint |
| `cluster_certificate_authority` | Base64 CA data for the cluster |
| `kubeconfig_command` | Command to configure kubectl |

## Security notes

- Nodes run in public subnets with public IPs; all inbound traffic is blocked by the EKS-managed security groups.
- The public API endpoint is open to `0.0.0.0/0` by default — set `restrict_api_to_local_ip = true` to lock it down to the machine running `tofu` (resolved via [icanhazip.com](https://icanhazip.com) at plan/apply time), or set `public_access_cidrs` to a fixed range. Note the IP lookup re-runs on every plan/apply, so if your IP changes, the next apply will update the cluster to match.
- The identity running `tofu apply` is bootstrapped as a cluster admin via an EKS access entry (`authentication_mode = "API"`).
