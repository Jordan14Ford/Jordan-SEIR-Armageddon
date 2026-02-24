# ============================================================================
# VPC ENDPOINTS FOR PRIVATE ARCHITECTURE (BONUS-A)
# ============================================================================
#
# These endpoints allow EC2 instances in private subnets to access AWS
# services without internet gateway or NAT gateway dependency.
#
# Endpoint types:
# - Gateway: Free, used for S3 and DynamoDB
# - Interface: Charged hourly, used for most AWS services
#
# ============================================================================

# ============================================================================
# DATA SOURCES - Existing VPC Endpoints (created manually)
# ============================================================================

data "aws_vpc_endpoint" "ssm" {
  vpc_id       = aws_vpc.lab1c.id
  service_name = "com.amazonaws.us-east-2.ssm"

  filter {
    name   = "vpc-endpoint-id"
    values = ["vpce-080d0229f1c6c229e"]
  }
}

data "aws_vpc_endpoint" "ssmmessages" {
  vpc_id       = aws_vpc.lab1c.id
  service_name = "com.amazonaws.us-east-2.ssmmessages"

  filter {
    name   = "vpc-endpoint-id"
    values = ["vpce-048a413f0b999c523"]
  }
}

data "aws_vpc_endpoint" "ec2messages" {
  vpc_id       = aws_vpc.lab1c.id
  service_name = "com.amazonaws.us-east-2.ec2messages"

  filter {
    name   = "vpc-endpoint-id"
    values = ["vpce-0bf242a7bafe255cb"]
  }
}

# ============================================================================
# S3 GATEWAY ENDPOINT (FREE - no hourly charge)
# ============================================================================

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.lab1c.id
  service_name = "com.amazonaws.us-east-2.s3"

  vpc_endpoint_type = "Gateway"

  # Associate with both public and private route tables
  # This allows S3 access from any subnet
  route_table_ids = [
    aws_route_table.public.id,
    aws_route_table.private.id
  ]

  tags = {
    Name    = "lab1c-s3-gateway-endpoint"
    Project = "Lab 1C"
    Phase   = "1B-VPC-Endpoints"
  }
}

# ============================================================================
# SECRETS MANAGER INTERFACE ENDPOINT
# ============================================================================

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = aws_vpc.lab1c.id
  service_name      = "com.amazonaws.us-east-2.secretsmanager"
  vpc_endpoint_type = "Interface"

  # Private DNS enables using standard AWS SDK/CLI commands
  # without special endpoint URLs
  private_dns_enabled = true

  # Place endpoint ENIs in all private subnets for high availability
  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2b.id,
    aws_subnet.private_2c.id
  ]

  # Reference existing security group via data source
  security_group_ids = [
    data.aws_security_group.vpc_endpoints.id
  ]

  tags = {
    Name    = "lab1c-secretsmanager-endpoint"
    Project = "Lab 1C"
    Phase   = "1B-VPC-Endpoints"
  }
}

# ============================================================================
# CLOUDWATCH LOGS INTERFACE ENDPOINT
# ============================================================================

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.lab1c.id
  service_name      = "com.amazonaws.us-east-2.logs"
  vpc_endpoint_type = "Interface"

  private_dns_enabled = true

  subnet_ids = [
    aws_subnet.private_2a.id,
    aws_subnet.private_2b.id,
    aws_subnet.private_2c.id
  ]

  security_group_ids = [
    data.aws_security_group.vpc_endpoints.id
  ]

  tags = {
    Name    = "lab1c-logs-endpoint"
    Project = "Lab 1C"
    Phase   = "1B-VPC-Endpoints"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "vpc_endpoint_s3_id" {
  description = "ID of S3 Gateway Endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "vpc_endpoint_s3_prefix_list_id" {
  description = "Prefix list ID of S3 Gateway Endpoint (for route tables)"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}

output "vpc_endpoint_secretsmanager_id" {
  description = "ID of Secrets Manager Interface Endpoint"
  value       = aws_vpc_endpoint.secretsmanager.id
}

output "vpc_endpoint_secretsmanager_dns_entries" {
  description = "DNS entries for Secrets Manager endpoint"
  value       = aws_vpc_endpoint.secretsmanager.dns_entry
}

output "vpc_endpoint_logs_id" {
  description = "ID of CloudWatch Logs Interface Endpoint"
  value       = aws_vpc_endpoint.logs.id
}

output "vpc_endpoint_logs_dns_entries" {
  description = "DNS entries for CloudWatch Logs endpoint"
  value       = aws_vpc_endpoint.logs.dns_entry
}

output "existing_vpc_endpoints" {
  description = "Existing VPC endpoints (data sources, not managed by Terraform)"
  value = {
    ssm = {
      id           = data.aws_vpc_endpoint.ssm.id
      service_name = data.aws_vpc_endpoint.ssm.service_name
    }
    ssmmessages = {
      id           = data.aws_vpc_endpoint.ssmmessages.id
      service_name = data.aws_vpc_endpoint.ssmmessages.service_name
    }
    ec2messages = {
      id           = data.aws_vpc_endpoint.ec2messages.id
      service_name = data.aws_vpc_endpoint.ec2messages.service_name
    }
  }
}