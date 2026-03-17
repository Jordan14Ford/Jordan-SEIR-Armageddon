# tokyo networking
# vpc, subnets, nat gateway, route tables

# VPC
resource "aws_vpc" "tokyo_vpc" {
  cidr_block           = var.tokyo_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true # Required for RDS endpoint resolution and SSM

  tags = {
    Name = "${var.project}-tokyo-vpc"
  }
}

# internet gateway
resource "aws_internet_gateway" "tokyo_igw" {
  vpc_id = aws_vpc.tokyo_vpc.id

  tags = {
    Name = "${var.project}-tokyo-igw"
  }
}

# public subnets - ALB goes here
# need 2 AZs for ALB requirement
resource "aws_subnet" "tokyo_public_1" {
  vpc_id                  = aws_vpc.tokyo_vpc.id
  cidr_block              = var.tokyo_public_subnet_1_cidr
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-tokyo-public-1a"
    Tier = "public"
  }
}

resource "aws_subnet" "tokyo_public_2" {
  vpc_id                  = aws_vpc.tokyo_vpc.id
  cidr_block              = var.tokyo_public_subnet_2_cidr
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-tokyo-public-1c"
    Tier = "public"
  }
}

# private subnets - EC2 and RDS go here
resource "aws_subnet" "tokyo_private_1" {
  vpc_id            = aws_vpc.tokyo_vpc.id
  cidr_block        = var.tokyo_private_subnet_1_cidr
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${var.project}-tokyo-private-1a"
    Tier = "private"
  }
}

resource "aws_subnet" "tokyo_private_2" {
  vpc_id            = aws_vpc.tokyo_vpc.id
  cidr_block        = var.tokyo_private_subnet_2_cidr
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${var.project}-tokyo-private-1c"
    Tier = "private"
  }
}

# NAT gateway stuff - this is expensive (~$32/mo), destroy when not using
resource "aws_eip" "tokyo_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-tokyo-nat-eip"
  }

  # NAT EIP must not be created before the IGW exists
  depends_on = [aws_internet_gateway.tokyo_igw]
}

# NAT gateway - has to be in public subnet (took me a while to figure this out)
resource "aws_nat_gateway" "tokyo_nat" {
  allocation_id = aws_eip.tokyo_nat_eip.id
  subnet_id     = aws_subnet.tokyo_public_1.id # NAT GW lives in public subnet

  tags = {
    Name = "${var.project}-tokyo-nat"
  }

  depends_on = [aws_internet_gateway.tokyo_igw]
}

# route tables
resource "aws_route_table" "tokyo_public_rt" {
  vpc_id = aws_vpc.tokyo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tokyo_igw.id
  }

  tags = {
    Name = "${var.project}-tokyo-public-rt"
  }
}

resource "aws_route_table_association" "tokyo_public_1_assoc" {
  subnet_id      = aws_subnet.tokyo_public_1.id
  route_table_id = aws_route_table.tokyo_public_rt.id
}

resource "aws_route_table_association" "tokyo_public_2_assoc" {
  subnet_id      = aws_subnet.tokyo_public_2.id
  route_table_id = aws_route_table.tokyo_public_rt.id
}

# private route table - TGW route added in routes.tf
resource "aws_route_table" "tokyo_private_rt" {
  vpc_id = aws_vpc.tokyo_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.tokyo_nat.id
  }

  tags = {
    Name = "${var.project}-tokyo-private-rt"
  }
}

resource "aws_route_table_association" "tokyo_private_1_assoc" {
  subnet_id      = aws_subnet.tokyo_private_1.id
  route_table_id = aws_route_table.tokyo_private_rt.id
}

resource "aws_route_table_association" "tokyo_private_2_assoc" {
  subnet_id      = aws_subnet.tokyo_private_2.id
  route_table_id = aws_route_table.tokyo_private_rt.id
}
