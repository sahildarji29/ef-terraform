# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nat-eip"
    }
  )

  depends_on = [data.aws_vpc.existing]
}

# NAT Gateway in first public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_ids[0]  # Use first public subnet

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-nat-gateway"
    }
  )

  depends_on = [aws_eip.nat]
}

# Route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-private-rt"
    }
  )
}

# Associate private subnets with the route table
resource "aws_route_table_association" "private" {
  for_each = toset(var.private_subnet_ids)

  subnet_id      = each.value
  route_table_id = aws_route_table.private.id
}

