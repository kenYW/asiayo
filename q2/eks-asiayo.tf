locals {
  asiayo_cluster_version          = "1.30"
  asiayo_node_ami_minor_version   = "v20240703"
  asiayo_addon_vpc_cni_version    = "v1.18.2-eksbuild.1"
  asiayo_addon_kube_proxy_version = "v1.30.0-eksbuild.3"
  asiayo_addon_coredns_version    = "v1.11.1-eksbuild.9"
}

# default eks ami
data "aws_ami" "asiayo_eks_default" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-node-${local.asiayo_cluster_version}-v*"]
  }
}

# default eks arm ami
data "aws_ami" "asiayo_eks_default_arm" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amazon-eks-arm64-node-${local.asiayo_cluster_version}-v*"]
  }
}


module "asiayo_eks" {
  source                          = "./modules/aws-eks"
  cluster_name                    = "q2-asiayo"
  cluster_version                 = local.asiayo_cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  # disable timestamp prefix at end of resources
  iam_role_use_name_prefix               = false
  cluster_security_group_use_name_prefix = false
  node_security_group_use_name_prefix    = false
  # IPV6
  #cluster_ip_family = "ipv6"

  cluster_enabled_log_types = ["scheduler", "controllerManager", "authenticator", "api", "audit"]
  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
      configuration_values = jsonencode({
        env = {
          AWS_VPC_K8S_CNI_EXTERNALSNAT = "true",
          CLUSTER_ENDPOINT             = module.asiayo_eks.cluster_endpoint
          MINIMUM_IP_TARGET            = "5",
          WARM_IP_TARGET               = "1"
        }
      })
    }
  }

  vpc_id     = local.vpc_id
  subnet_ids = concat(data.aws_subnet.infra.*.id)

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_allow_access_from_control_plane = {
      type                          = "ingress"
      protocol                      = "tcp"
      from_port                     = 9443
      to_port                       = 9443
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
    }
    ingress_admission_webhook_controller = {
      protocol                      = "tcp"
      from_port                     = 8443
      to_port                       = 8443
      type                          = "ingress"
      source_cluster_security_group = true
      description                   = "Allow access from control plane to webhook port of asiayo ingress"
    }
    keda_allow_discovery_check = {
      protocol                      = "tcp"
      from_port                     = 6443
      to_port                       = 6443
      type                          = "ingress"
      source_cluster_security_group = true
      description                   = "Allow access from control plane to keda metrics api service"
    }
    metric_server_discovery_check = {
      protocol                      = "tcp"
      from_port                     = 4443
      to_port                       = 4443
      type                          = "ingress"
      source_cluster_security_group = true
      description                   = "Allow access from control plane to metrics server api service"
    }
  }
  eks_managed_node_group_defaults = {
    // ==== managed node_group template {} ===
    ami_type       = "AL2_x86_64"
    disk_size      = 50
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
    tags = {
      "user:project"     = "asiayo"
      "user:application" = "k8s"
      "user:costowner"   = "asiayo:shared"
    }


  }
  # for nodegroup replacement operation, please comment out/in apply to avoid conflict naming.
  eks_managed_node_groups = {
    // =======managed node_group modules {}==========
    "q2-asiayo-common-1a" = {
      name                 = "q2-asiayo-common-5a"
      description          = "q2-asiayo-common-5a launch template"
      subnet_ids           = [data.aws_subnet.infra[0].id]
      bootstrap_extra_args = "--container-runtime containerd --dns-cluster-ip 169.254.20.10"
      create_iam_role      = false
      iam_role_arn         = aws_iam_role.nodegroup.arn
      instance_types       = ["m5.2xlarge", "m5a.2xlarge"]
      max_size             = 3
      labels = {
        service = "common"
      }
      tags = {
        "user:project"     = "asiayo"
        "user:application" = "k8s"
        "user:costowner"   = "asiayo:shared"
      }
    }
    "q2-asiayo-common-1b" = {
      name                 = "q2-asiayo-common-5b"
      description          = "q2-asiayo-common-5b launch template"
      subnet_ids           = [data.aws_subnet.infra[1].id]
      bootstrap_extra_args = "--container-runtime containerd --dns-cluster-ip 169.254.20.10"
      create_iam_role      = false
      iam_role_arn         = aws_iam_role.nodegroup.arn
      instance_types       = ["m5.2xlarge", "m5a.2xlarge"]
      max_size             = 3
      labels = {
        service = "common"
      }
      tags = {
        "user:project"     = "asiayo"
        "user:application" = "k8s"
        "user:costowner"   = "asiayo:shared"
      }
    }
    "q2-asiayo-common-1c" = {
      name                 = "q2-asiayo-common-5c"
      description          = "q2-asiayo-common-5c launch template"
      subnet_ids           = [data.aws_subnet.infra[2].id]
      create_iam_role      = false
      bootstrap_extra_args = "--container-runtime containerd --dns-cluster-ip 169.254.20.10"
      iam_role_arn         = aws_iam_role.nodegroup.arn
      instance_types       = ["m5.2xlarge", "m5a.2xlarge"]
      max_size             = 3
      labels = {
        service = "common"
      }
      tags = {
        "user:project"     = "asiayo"
        "user:application" = "k8s"
        "user:costowner"   = "asiayo:shared"
      }
    }

  }
  tags = {
    "user:project"     = "asiayo"
    "user:application" = "k8s"
    "user:costowner"   = "asiayo:shared"
  }
}






# sleep 5 * 60 = 300s timeout
variable "asiayo_wait_for_cluster_cmd" {
  description = "Custom local-exec command to execute for determining if the eks cluster is healthy. Cluster endpoint will be available as an environment variable called ENDPOINT"
  type        = string
  default     = "for i in `seq 1 60`; do wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null && exit 0 || true; sleep 5; done; echo TIMEOUT && exit 1"
}

variable "asiayo_wait_for_cluster_interpreter" {
  description = "Custom local-exec command line interpreter for the command to determining if the eks cluster is healthy."
  type        = list(string)
  default     = ["/bin/sh", "-c"]
}

resource "null_resource" "asiayo_wait_for_cluster" {

  provisioner "local-exec" {
    command     = var.asiayo_wait_for_cluster_cmd
    interpreter = var.asiayo_wait_for_cluster_interpreter
    environment = {
      ENDPOINT = module.asiayo_eks.cluster_endpoint
    }
  }
}

resource "null_resource" "asiayo_eks_setup" {
  depends_on = [null_resource.asiayo_wait_for_cluster]
  triggers = {
    #always_run = "${timestamp()}"
    always_run = module.asiayo_eks.cluster_endpoint
  }
  // -- template and provision "k8s infra"
  provisioner "local-exec" {
    command = format(
      "cat <<\"EOF\" > \"%s\"\n%s\nEOF",
      "./k8s/${module.asiayo_eks.cluster_id}.config",
      templatefile("./templates/kubeconfig.tpl", {
        kubeconfig_name     = module.asiayo_eks.cluster_arn
        endpoint            = module.asiayo_eks.cluster_endpoint
        cluster_auth_base64 = module.asiayo_eks.cluster_certificate_authority_data
        cluster_name        = module.asiayo_eks.cluster_id
        region              = local.region
      })
    )
  }
  provisioner "local-exec" {
    command = format("chmod 600 %s", "./k8s/${module.asiayo_eks.cluster_id}.config")
  }
  // -- template end
  # executing commands
  provisioner "local-exec" {
    command = format("./k8s/eks-setup.sh %s", module.asiayo_eks.cluster_id)
  }
}
