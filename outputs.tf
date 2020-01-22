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
