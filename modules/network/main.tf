# Data source for existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Data source for existing subnets
data "aws_subnets" "public" {
  filter {
    name   = "subnet-id"
    values = var.public_subnet_ids
  }
}

# Get individual subnet details
data "aws_subnet" "public" {
  for_each = toset(var.public_subnet_ids)
  id       = each.value
}