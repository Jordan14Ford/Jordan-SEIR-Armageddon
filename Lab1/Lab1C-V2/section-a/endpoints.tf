# Bonus-A — VPC Endpoints
# Private EC2 has no internet route, so every AWS API call must
# go through one of these endpoints. Without them SSM, Secrets
# Manager, and CloudWatch are unreachable from private subnets.

resource "aws_security_group" "cloudyjones_endpoint_sg01" {
  name        = "${var.project}-endpoint-sg01"
  description = "Allow HTTPS from private subnets to VPC endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from private subnets only"
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

resource "aws_vpc_endpoint" "cloudyjones_ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-ssm-endpoint", Project = var.project }
}

resource "aws_vpc_endpoint" "cloudyjones_ec2messages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-ec2messages-endpoint", Project = var.project }
}

resource "aws_vpc_endpoint" "cloudyjones_ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-ssmmessages-endpoint", Project = var.project }
}

resource "aws_vpc_endpoint" "cloudyjones_logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-logs-endpoint", Project = var.project }
}

resource "aws_vpc_endpoint" "cloudyjones_secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-secretsmanager-endpoint", Project = var.project }
}

resource "aws_vpc_endpoint" "cloudyjones_monitoring" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = { Name = "${var.project}-monitoring-endpoint", Project = var.project }
}

# S3 Gateway endpoint — free, routes S3 traffic over AWS backbone
# also needed for yum package installs (repos are on S3)
resource "aws_vpc_endpoint" "cloudyjones_s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [var.private_rt_id]

  tags = { Name = "${var.project}-s3-endpoint", Project = var.project }
}
