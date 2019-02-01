variable "vpc_id" {
  description = "(required) ID of the VPC to which the EKS cluster will be deployed"
  default     = ""
}

variable "subnet_ids" {
  description = "(required) IDs of the subnets to which the EKS worker nodes will be deployed"
  default     = []
}

variable "env" {
  description = "(optional) Unique identifier used to name all resources"
  default     = "default"
}

variable "tags" {
  description = "(optional) Additional tags applied to all resources"
  default     = {}
}

variable "kubernetes_version" {
  description = "(optional) https://www.terraform.io/docs/providers/aws/r/eks_cluster.html#version"
  default     = ""
}

variable "linux_instance_type" {
  description = "(optional) Linux worker node instance type"
  default     = "m5.large"
}

variable "linux_ami_prefix" {
  description = "(optional) String used to search for linux worker node AMI"
  default     = "amazon-eks-node"
}

variable "linux_disk_size" {
  description = "(optional) Size of the root volume for linux worker nodes"
  default     = "20"
}

variable "linux_node_count" {
  description = "(optional) Static amount of linux worker nodes"
  default     = "2"
}
