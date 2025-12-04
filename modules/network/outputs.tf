output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.existing.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = data.aws_vpc.existing.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = var.public_subnet_ids
}

output "public_subnets" {
  description = "Map of public subnet details"
  value = {
    for k, v in data.aws_subnet.public : k => {
      id                = v.id
      availability_zone = v.availability_zone
      cidr_block        = v.cidr_block
    }
  }
}