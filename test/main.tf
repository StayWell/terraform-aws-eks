module "this" {
  source             = "../"
  public_subnet_ids  = aws_subnet.public.id
  private_subnet_ids = aws_subnet.private.id
}

data "aws_availability_zones" "this" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  availability_zone = data.aws_availability_zones.this.names[0]
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 0)
  vpc_id            = aws_vpc.this.id

  tags = {
    "kubernetes.io/cluster/${module.this.cluster_id}" = "shared"
  }
}

resource "aws_subnet" "private" {
  availability_zone = data.aws_availability_zones.this.names[1]
  cidr_block        = cidrsubnet(aws_vpc.this.cidr_block, 8, 1)
  vpc_id            = aws_vpc.this.id

  tags = {
    "kubernetes.io/cluster/${module.this.cluster_id}" = "shared"
  }
}
