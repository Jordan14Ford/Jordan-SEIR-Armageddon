# Security group for VPC Interface Endpoints
# Allows HTTPS from private subnets only
resource "aws_security_group" "cloudyjones_endpoint_sg01" {
  name        = "${var.project}-endpoint-sg01"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

  ingress {
    description = "HTTPS from private subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project}-endpoint-sg01"
    Project = var.project
  }
}

# SSM endpoint — required for Session Manager
resource "aws_vpc_endpoint" "cloudyjones_ssm" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-ssm-endpoint"
    Project = var.project
  }
}

# EC2Messages endpoint — required for Session Manager
resource "aws_vpc_endpoint" "cloudyjones_ec2messages" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-ec2messages-endpoint"
    Project = var.project
  }
}

# SSMMessages endpoint — required for Session Manager
resource "aws_vpc_endpoint" "cloudyjones_ssmmessages" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-ssmmessages-endpoint"
    Project = var.project
  }
}

# CloudWatch Logs endpoint — log shipping without internet
resource "aws_vpc_endpoint" "cloudyjones_logs" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-logs-endpoint"
    Project = var.project
  }
}

# Secrets Manager endpoint — credential retrieval without internet
resource "aws_vpc_endpoint" "cloudyjones_secretsmanager" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-secretsmanager-endpoint"
    Project = var.project
  }
}

# S3 Gateway endpoint — free, no SG needed, handles yum/package repos
resource "aws_vpc_endpoint" "cloudyjones_s3" {
  vpc_id            = aws_vpc.cloudyjones_vpc01.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.cloudyjones_private_rt01.id]

  tags = {
    Name    = "${var.project}-s3-endpoint"
    Project = var.project
  }
}