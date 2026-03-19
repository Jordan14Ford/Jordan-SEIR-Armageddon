# osaka networking - failover region for tokyo
# vpc, subnets, nat, route tables

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# VPC
resource "aws_vpc" "osaka_vpc" {
  cidr_block           = var.osaka_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-osaka-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "osaka_igw" {
  vpc_id = aws_vpc.osaka_vpc.id

  tags = {
    Name = "${var.project}-osaka-igw"
  }
}

# public subnets - ALB needs 2 AZs
resource "aws_subnet" "osaka_public_1" {
  vpc_id                  = aws_vpc.osaka_vpc.id
  cidr_block              = var.osaka_public_subnet_1_cidr
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-osaka-public-3a"
    Tier = "public"
  }
}

resource "aws_subnet" "osaka_public_2" {
  vpc_id                  = aws_vpc.osaka_vpc.id
  cidr_block              = var.osaka_public_subnet_2_cidr
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-osaka-public-3b"
    Tier = "public"
  }
}

# private subnets - EC2 goes here
resource "aws_subnet" "osaka_private_1" {
  vpc_id            = aws_vpc.osaka_vpc.id
  cidr_block        = var.osaka_private_subnet_1_cidr
  availability_zone = "ap-northeast-3a"

  tags = {
    Name = "${var.project}-osaka-private-3a"
    Tier = "private"
  }
}

resource "aws_subnet" "osaka_private_2" {
  vpc_id            = aws_vpc.osaka_vpc.id
  cidr_block        = var.osaka_private_subnet_2_cidr
  availability_zone = "ap-northeast-3b"

  tags = {
    Name = "${var.project}-osaka-private-3b"
    Tier = "private"
  }
}

# NAT gateway - expensive, ~$32/mo
resource "aws_eip" "osaka_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-osaka-nat-eip"
  }

  depends_on = [aws_internet_gateway.osaka_igw]
}

resource "aws_nat_gateway" "osaka_nat" {
  allocation_id = aws_eip.osaka_nat_eip.id
  subnet_id     = aws_subnet.osaka_public_1.id

  tags = {
    Name = "${var.project}-osaka-nat"
  }

  depends_on = [aws_internet_gateway.osaka_igw]
}

# route tables
resource "aws_route_table" "osaka_public_rt" {
  vpc_id = aws_vpc.osaka_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.osaka_igw.id
  }

  tags = {
    Name = "${var.project}-osaka-public-rt"
  }
}

resource "aws_route_table_association" "osaka_public_1_assoc" {
  subnet_id      = aws_subnet.osaka_public_1.id
  route_table_id = aws_route_table.osaka_public_rt.id
}

resource "aws_route_table_association" "osaka_public_2_assoc" {
  subnet_id      = aws_subnet.osaka_public_2.id
  route_table_id = aws_route_table.osaka_public_rt.id
}

# private route table - TGW route added in routes.tf
resource "aws_route_table" "osaka_private_rt" {
  vpc_id = aws_vpc.osaka_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.osaka_nat.id
  }

  tags = {
    Name = "${var.project}-osaka-private-rt"
  }
}

resource "aws_route_table_association" "osaka_private_1_assoc" {
  subnet_id      = aws_subnet.osaka_private_1.id
  route_table_id = aws_route_table.osaka_private_rt.id
}

resource "aws_route_table_association" "osaka_private_2_assoc" {
  subnet_id      = aws_subnet.osaka_private_2.id
  route_table_id = aws_route_table.osaka_private_rt.id
}
