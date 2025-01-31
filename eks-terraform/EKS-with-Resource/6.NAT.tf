resource "aws_eip" "natEip" {
  domain = "vpc"

  tags = {
    Name = "${local.cluster_name}-natEip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.natEip.id
  subnet_id = aws_subnet.public_zone1.id

  tags = {
    Name = "${local.cluster_name}-nat"
  }
}