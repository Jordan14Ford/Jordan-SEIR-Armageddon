# ============================================================
# vpc.tf — custom VPC for Lab 1C private cloud architecture
# goal: get EC2 off the default VPC and into a proper
# network with public/private subnet separation
# ============================================================

# main VPC - using a /16 so we have plenty of room to carve subnets
# DNS settings required for SSM Session Manager and VPC endpoints to work
resource "aws_vpc" "cloudyjones_vpc01" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true  # needed for endpoint DNS resolution
  enable_dns_support   = true

  tags = {
    Name    = "${var.project}-vpc01"
    Project = var.project
  }
}

# public subnets — ALB needs to live here to accept internet traffic
# using count so both subnets get created from the same block
# map_public_ip_on_launch = true so anything launched here gets a public IP
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

# private subnets — EC2 lives here with no public IP
# only way in is through the ALB → security group trust relationship
# only way out to AWS APIs is through VPC endpoints (no NAT = no extra cost)
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

# internet gateway — attached to VPC, gives public subnets a path to internet
# without this the ALB can't receive traffic from outside
resource "aws_internet_gateway" "cloudyjones_igw01" {
  vpc_id = aws_vpc.cloudyjones_vpc01.id

  tags = {
    Name    = "${var.project}-igw01"
    Project = var.project
  }
}

# public route table — any traffic going to 0.0.0.0/0 goes through IGW
# this is what makes the public subnets actually "public"
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

# private route table — intentionally has NO internet route
# EC2 reaches AWS services (SSM, Secrets Manager, CloudWatch) via VPC endpoints
# this is the whole point of the private architecture pattern
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

# pull available AZs dynamically so this works in any region
data "aws_availability_zones" "available" {
  state = "available"
}