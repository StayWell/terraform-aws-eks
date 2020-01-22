module "this" {
  source     = "StayWell/eks/aws"
  version    = "1.0.0"
  subnet_ids = ["your", "subnets"]
}
