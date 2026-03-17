# ============================================================
# endpoints.tf — VPC Interface Endpoints
#
# key insight: private EC2 has no internet route, so it can't
# reach AWS APIs the normal way. VPC endpoints create a private
# path directly into AWS services without leaving the VPC.
#
# interface endpoints = ENI in your subnet, costs ~$0.01/hr each
# gateway endpoints = route table entry, free (S3 only)
# ============================================================

# endpoint SG — only allows HTTPS from private subnet CIDRs
# the EC2 instance calls the endpoint over port 443
# no need to open this to the public subnets
resource "aws_security_group" "cloudyjones_endpoint_sg01" {
  name        = "${var.project}-endpoint-sg01"
  description = "Allow HTTPS from private subnets to VPC endpoints"
  vpc_id      = aws_vpc.cloudyjones_vpc01.id

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

# SSM endpoint — this is what lets Session Manager connect to the instance
# without it, ssm start-session fails with a connection timeout
resource "aws_vpc_endpoint" "cloudyjones_ssm" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true # resolves ssm.us-east-1.amazonaws.com locally

  tags = {
    Name    = "${var.project}-ssm-endpoint"
    Project = var.project
  }
}

# EC2Messages + SSMMessages — both required for SSM Session Manager
# learned this the hard way: ssm endpoint alone isn't enough
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

# CloudWatch Logs endpoint — Flask app logs ship here via the agent
# without this, log groups never receive data from the private instance
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

# Secrets Manager endpoint — app fetches DB credentials here at runtime
# this is the secure pattern: no hardcoded creds in code or env vars
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

# CloudWatch Monitoring endpoint — needed for PutMetricData from private EC2
# without this, the app's DBConnectionErrors metric never reaches CloudWatch
resource "aws_vpc_endpoint" "cloudyjones_monitoring" {
  vpc_id              = aws_vpc.cloudyjones_vpc01.id
  service_name        = "com.amazonaws.${var.aws_region}.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.cloudyjones_private_subnets[*].id
  security_group_ids  = [aws_security_group.cloudyjones_endpoint_sg01.id]
  private_dns_enabled = true

  tags = {
    Name    = "${var.project}-monitoring-endpoint"
    Project = var.project
  }
}

# S3 Gateway endpoint — free, no hourly charge unlike interface endpoints
# routes S3 traffic through AWS backbone instead of internet
# also needed for yum package installs on Amazon Linux (yum repos are on S3)
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