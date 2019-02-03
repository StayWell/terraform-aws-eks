# terraform-aws-eks

Creates all resources needed for an EKS cluster

## Usage

```terraform
module "this" {
  source     = "github.com/jjno91/terraform-aws-eks?ref=master"
  vpc_id     = "your-vpc"
  subnet_ids = ["your", "subnets"]
}
```

## linux_target_group_arns

The intent with this variable is to allow you to deploy NodePort Kubernetes services, place the worker nodes in ALB target groups via this variable, and then manage ingress directly through Terraform's AWS provider rather than through a SIG Kubernetes controller
