resource "aws_vpc" "cloudyjones_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project}-vpc01"
    Project = var.project
  }
}

resource "aws_subnet" "cloudyjones_public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.cloudyjones_vpc01.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-public-subnet-${count.index + 1}"
    Project = var.project
  }
}

resource "aws_subnet" "cloudyjones_private_subnets" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.cloudyjones_vpc01.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-private-subnet-${count.index + 1}"
    Project = var.project
  }
}

resource "aws_internet_gateway" "cloudyjones_igw01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  tags = {
    Name    = "${var.project}-igw01"
    Project = var.project
  }
}

resource "aws_route_table" "cloudyjones_public_rt01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudyjones_igw01.id
  }

  tags = {
    Name    = "${var.project}-public-rt01"
    Project = var.project
  }
}

resource "aws_route_table_association" "cloudyjones_public_rta" {
  count          = length(aws_subnet.cloudyjones_public_subnets)
  subnet_id      = aws_subnet.cloudyjones_public_subnets[count.index].id
  route_table_id = aws_route_table.cloudyjones_public_rt01.id
}

# private route table — no internet route; EC2 uses VPC endpoints only
resource "aws_route_table" "cloudyjones_private_rt01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  tags = {
    Name    = "${var.project}-private-rt01"
    Project = var.project
  }
}

resource "aws_route_table_association" "cloudyjones_private_rta" {
  count          = length(aws_subnet.cloudyjones_private_subnets)
  subnet_id      = aws_subnet.cloudyjones_private_subnets[count.index].id
  route_table_id = aws_route_table.cloudyjones_private_rt01.id
}

data "aws_availability_zones" "available" {
  state = "available"
}

# optional NAT — toggle with var.enable_nat for strict Bonus-A no-internet posture
resource "aws_eip" "cloudyjones_nat_eip" {
  count  = var.enable_nat ? 1 : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "cloudyjones_nat_gw" {
  count         = var.enable_nat ? 1 : 0
  allocation_id = aws_eip.cloudyjones_nat_eip[0].id
  subnet_id     = aws_subnet.cloudyjones_public_subnets[0].id

  tags = {
    Name    = "${var.project}-nat-gw"
    Project = var.project
  }
}

resource "aws_route" "cloudyjones_private_internet" {
  count                  = var.enable_nat ? 1 : 0
  route_table_id         = aws_route_table.cloudyjones_private_rt01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.cloudyjones_nat_gw[0].id
}
