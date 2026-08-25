# trivy:ignore:AVD-AWS-0040 -- Public API access is restricted to operator-supplied trusted CIDRs; private access remains enabled.
# trivy:ignore:AVD-AWS-0104 -- Private nodes require outbound bootstrap and registry access through NAT; workload egress is constrained by NetworkPolicy.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.24.1"

  name               = local.name
  kubernetes_version = var.kubernetes_version

  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  endpoint_private_access      = true
  endpoint_public_access       = true
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  enabled_log_types                      = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = 7
  deletion_protection                    = false

  addons = {
    coredns = {
      addon_version = "v1.13.2-eksbuild.11"
    }
    eks-pod-identity-agent = {
      addon_version = "v1.3.10-eksbuild.3"
    }
    kube-proxy = {
      addon_version = "v1.35.3-eksbuild.18"
    }
    vpc-cni = {
      addon_version               = "v1.22.4-eksbuild.3"
      before_compute              = true
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    platform = {
      name                     = "${local.name}-platform"
      iam_role_name            = "${local.name}-node"
      iam_role_use_name_prefix = false
      ami_type                 = "AL2023_x86_64_STANDARD"
      instance_types           = var.node_instance_types
      capacity_type            = "ON_DEMAND"

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      use_latest_ami_release_version = true

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 30
            volume_type           = "gp3"
            encrypted             = true
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 1
      }

      update_config = {
        max_unavailable = 1
      }

      labels = {
        role = "platform"
      }

      tags = {
        "k8s.io/cluster-autoscaler/enabled"       = "true"
        "k8s.io/cluster-autoscaler/${local.name}" = "owned"
      }
    }
  }

  tags = local.common_tags
}
