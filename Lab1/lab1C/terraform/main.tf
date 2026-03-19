# ============================================================
# VPC
# ============================================================
resource "aws_vpc" "lab1c" {
  cidr_block           = "10.236.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab 1-VPC"
  }
}

# ============================================================
# Public Subnets (Ingress / ALB)
# ============================================================
resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public1-us-east-2a"
  }
}

resource "aws_subnet" "public_2b" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public2-us-east-2b"
  }
}

resource "aws_subnet" "public_2c" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.3.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-public3-us-east-2c"
  }
}

# ============================================================
# Private Subnets (Compute / Data)
# ============================================================
resource "aws_subnet" "private_2a" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.11.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-private1-us-east-2a"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.12.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-private2-us-east-2b"
  }
}

resource "aws_subnet" "private_2c" {
  vpc_id                  = aws_vpc.lab1c.id
  cidr_block              = "10.236.13.0/24"
  availability_zone       = "us-east-2c"
  map_public_ip_on_launch = false

  tags = {
    Name = "subnet-private3-us-east-2c"
  }
}

# ============================================================
# Internet Gateway
# ============================================================
resource "aws_internet_gateway" "lab1c" {
  vpc_id = aws_vpc.lab1c.id

  tags = {
    Name = "igw"
  }
}

# ============================================================
# Route Tables
# ============================================================

# Public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lab1c.id

  tags = {
    Name = "rtb-public"
  }
}

# Public route to Internet Gateway
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.lab1c.id
}

# Private route table (NO NAT, NO internet)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lab1c.id

  tags = {
    Name = "rtb-private"
  }
}

# ============================================================
# Main Route Table Association
# NOTE: Private route table is the VPC main route table.
# This matches AWS brownfield reality and avoids explicit
# private subnet associations.
# ============================================================
resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.lab1c.id
  route_table_id = aws_route_table.private.id
}

# ============================================================
# Route Table Associations (Public Only)
# ============================================================
resource "aws_route_table_association" "public_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2c" {
  subnet_id      = aws_subnet.public_2c.id
  route_table_id = aws_route_table.public.id
}
