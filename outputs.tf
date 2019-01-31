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
