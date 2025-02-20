MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="//"

--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
${pre_bootstrap_user_data ~}

%{ if enable_bootstrap_user_data ~}
--//
Content-Type: application/node.eks.aws

apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    apiServerEndpoint: ${cluster_endpoint}
    certificateAuthority: ${cluster_auth_base64}
    cidr: 10.100.0.0/16
    name: ${cluster_name}

%{ endif ~}
--//
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash
set -e
${post_bootstrap_user_data ~}

--//--

