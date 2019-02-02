output "cluster_id" {
  description = "https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#id"
  value       = "${aws_eks_cluster.this.id}"
}

output "cluster_endpoint" {
  description = "https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#endpoint"
  value       = "${aws_eks_cluster.this.endpoint}"
}

output "cluster_ca_data" {
  description = "https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#data"
  value       = "${aws_eks_cluster.this.certificate_authority.0.data}"
}

output "worker_sg_id" {
  description = "Security group ID for the cluster's worker nodes"
  value       = "${aws_security_group.worker.id}"
}

output "control_sg_id" {
  description = "Security group ID for the cluster's control plane"
  value       = "${aws_security_group.control.id}"
}

output "worker_iam_role" {
  description = "IAM role for the EKS worker nodes"
  value       = "${aws_iam_role.worker.arn}"
}

locals {
  worker_config_map = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.worker.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF
}

output "worker_config_map" {
  description = "Kubernetes config map that must be loaded to the EKS cluster before worker nodes can connect"
  value       = "${local.worker_config_map}"
}

locals {
  kubeconfig = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.this.endpoint}
    certificate-authority-data: ${aws_eks_cluster.this.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.this.id}"
        # - "-r"
        # - "<role-arn>"
      # env:
        # - name: AWS_PROFILE
        #   value: "<aws-profile>"
EOF
}

output "kubeconfig" {
  description = "https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/"
  value       = "${local.kubeconfig}"
}
