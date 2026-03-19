# sao paulo networking
# mostly copied from tokyo, no RDS here though

resource "aws_vpc" "sao_paulo_vpc" {
  cidr_block           = var.sao_paulo_vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project}-sao-paulo-vpc"
  }
}

resource "aws_internet_gateway" "sao_paulo_igw" {
  vpc_id = aws_vpc.sao_paulo_vpc.id

  tags = {
    Name = "${var.project}-sao-paulo-igw"
  }
}

# public subnets
resource "aws_subnet" "sao_paulo_public_1" {
  vpc_id                  = aws_vpc.sao_paulo_vpc.id
  cidr_block              = var.sao_paulo_public_subnet_1_cidr
  availability_zone       = "sa-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-sao-paulo-public-1a"
    Tier = "public"
  }
}

resource "aws_subnet" "sao_paulo_public_2" {
  vpc_id                  = aws_vpc.sao_paulo_vpc.id
  cidr_block              = var.sao_paulo_public_subnet_2_cidr
  availability_zone       = "sa-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project}-sao-paulo-public-1b"
    Tier = "public"
  }
}

# private subnets - EC2 only, no RDS here
resource "aws_subnet" "sao_paulo_private_1" {
  vpc_id            = aws_vpc.sao_paulo_vpc.id
  cidr_block        = var.sao_paulo_private_subnet_1_cidr
  availability_zone = "sa-east-1a"

  tags = {
    Name = "${var.project}-sao-paulo-private-1a"
    Tier = "private"
  }
}

resource "aws_subnet" "sao_paulo_private_2" {
  vpc_id            = aws_vpc.sao_paulo_vpc.id
  cidr_block        = var.sao_paulo_private_subnet_2_cidr
  availability_zone = "sa-east-1b"

  tags = {
    Name = "${var.project}-sao-paulo-private-1b"
    Tier = "private"
  }
}

# NAT gateway - expensive, destroy when not using
resource "aws_eip" "sao_paulo_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-sao-paulo-nat-eip"
  }

  depends_on = [aws_internet_gateway.sao_paulo_igw]
}

resource "aws_nat_gateway" "sao_paulo_nat" {
  allocation_id = aws_eip.sao_paulo_nat_eip.id
  subnet_id     = aws_subnet.sao_paulo_public_1.id

  tags = {
    Name = "${var.project}-sao-paulo-nat"
  }

  depends_on = [aws_internet_gateway.sao_paulo_igw]
}

# route tables
resource "aws_route_table" "sao_paulo_public_rt" {
  vpc_id = aws_vpc.sao_paulo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sao_paulo_igw.id
  }

  tags = {
    Name = "${var.project}-sao-paulo-public-rt"
  }
}

resource "aws_route_table_association" "sao_paulo_public_1_assoc" {
  subnet_id      = aws_subnet.sao_paulo_public_1.id
  route_table_id = aws_route_table.sao_paulo_public_rt.id
}

resource "aws_route_table_association" "sao_paulo_public_2_assoc" {
  subnet_id      = aws_subnet.sao_paulo_public_2.id
  route_table_id = aws_route_table.sao_paulo_public_rt.id
}

# private route table - TGW route added in routes.tf
resource "aws_route_table" "sao_paulo_private_rt" {
  vpc_id = aws_vpc.sao_paulo_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sao_paulo_nat.id
  }

  tags = {
    Name = "${var.project}-sao-paulo-private-rt"
  }
}

resource "aws_route_table_association" "sao_paulo_private_1_assoc" {
  subnet_id      = aws_subnet.sao_paulo_private_1.id
  route_table_id = aws_route_table.sao_paulo_private_rt.id
}

resource "aws_route_table_association" "sao_paulo_private_2_assoc" {
  subnet_id      = aws_subnet.sao_paulo_private_2.id
  route_table_id = aws_route_table.sao_paulo_private_rt.id
}
