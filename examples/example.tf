module "this" {
  source     = "github.com/jjno91/terraform-aws-eks?ref=master"
  vpc_id     = "your-vpc"
  subnet_ids = ["your", "subnets"]
}
