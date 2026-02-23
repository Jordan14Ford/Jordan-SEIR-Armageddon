# Custom VPC — cloudyjones private architecture
resource "aws_vpc" "cloudyjones_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project}-vpc01"
    Project = var.project
  }
}

# Public subnets — ALB lives here
resource "aws_subnet" "cloudyjones_public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.cloudyjones_vpc01.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project}-public-subnet-${count.index + 1}"
    Project = var.project
  }
}

# Private subnets — EC2 and RDS live here
resource "aws_subnet" "cloudyjones_private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.cloudyjones_vpc01.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name    = "${var.project}-private-subnet-${count.index + 1}"
    Project = var.project
  }
}

# Internet Gateway — public subnets route through here
resource "aws_internet_gateway" "cloudyjones_igw01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  tags = {
    Name    = "${var.project}-igw01"
    Project = var.project
  }
}

# Public route table — sends 0.0.0.0/0 to IGW
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

# Associate public subnets with public route table
resource "aws_route_table_association" "cloudyjones_public_rta" {
  count          = length(aws_subnet.cloudyjones_public_subnets)
  subnet_id      = aws_subnet.cloudyjones_public_subnets[count.index].id
  route_table_id = aws_route_table.cloudyjones_public_rt01.id
}

# Private route table — no internet route (VPC endpoints handle AWS API traffic)
resource "aws_route_table" "cloudyjones_private_rt01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  tags = {
    Name    = "${var.project}-private-rt01"
    Project = var.project
  }
}

# Associate private subnets with private route table
resource "aws_route_table_association" "cloudyjones_private_rta" {
  count          = length(aws_subnet.cloudyjones_private_subnets)
  subnet_id      = aws_subnet.cloudyjones_private_subnets[count.index].id
  route_table_id = aws_route_table.cloudyjones_private_rt01.id
}

# Data source — get available AZs in region
data "aws_availability_zones" "available" {
  state = "available"
}