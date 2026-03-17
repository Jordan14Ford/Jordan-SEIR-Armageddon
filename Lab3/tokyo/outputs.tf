# =============================================================================
# LAB 3 — TOKYO OUTPUTS
# File: lab3/tokyo/outputs.tf
# Region: ap-northeast-1 (Tokyo)
# Purpose: Exports key values from the Tokyo state so São Paulo can consume
#          them via terraform_remote_state. Without these outputs, São Paulo
#          has no way to know the TGW ID, RDS endpoint, or Tokyo CIDR.
#
# HOW SÃO PAULO READS THESE:
#   In lab3/sao-paulo/variables.tf, Tokyo outputs are pulled like this:
#     data "terraform_remote_state" "tokyo" {
#       backend = "local"
#       config  = { path = "../tokyo/terraform.tfstate" }
#     }
#   Then referenced as:
#     data.terraform_remote_state.tokyo.outputs.tokyo_tgw_id
#
# APPLY ORDER REMINDER:
#   Always apply Tokyo first. São Paulo apply will fail if this state
#   file does not exist yet.
# =============================================================================


# Networking
output "tokyo_vpc_id" {
  description = "Tokyo VPC ID — used by São Paulo to verify TGW attachment targets the right VPC"
  value       = aws_vpc.tokyo_vpc.id
}

output "tokyo_vpc_cidr" {
  description = "Tokyo VPC CIDR (10.0.0.0/16) — São Paulo adds a route to this CIDR via its TGW"
  value       = aws_vpc.tokyo_vpc.cidr_block
}

output "tokyo_private_subnet_1_id" {
  description = "Tokyo private subnet 1 (ap-northeast-1a) — reference for TGW attachment and RDS"
  value       = aws_subnet.tokyo_private_1.id
}

output "tokyo_private_subnet_2_id" {
  description = "Tokyo private subnet 2 (ap-northeast-1c) — reference for TGW attachment and RDS"
  value       = aws_subnet.tokyo_private_2.id
}

output "tokyo_private_route_table_id" {
  description = "Tokyo private route table ID — TGW route for São Paulo CIDR is added to this table"
  value       = aws_route_table.tokyo_private_rt.id
}


# Database
output "tokyo_rds_endpoint" {
  description = "Tokyo RDS MySQL endpoint — São Paulo Flask app connects to this over the TGW corridor"
  value       = aws_db_instance.tokyo_rds.address
}

output "tokyo_rds_port" {
  description = "RDS port — always 3306 for MySQL, exported for clarity"
  value       = aws_db_instance.tokyo_rds.port
}

output "tokyo_db_name" {
  description = "Database name inside the RDS instance"
  value       = aws_db_instance.tokyo_rds.db_name
}


# ALB
output "tokyo_alb_dns" {
  description = "Tokyo ALB DNS name — use this to verify the Tokyo app tier is responding before wiring CloudFront"
  value       = aws_lb.tokyo_alb.dns_name
}


# Security Groups
output "tokyo_rds_sg_id" {
  description = "RDS security group ID — referenced when verifying the São Paulo CIDR ingress rule is in place"
  value       = aws_security_group.tokyo_rds_sg.id
}

output "tokyo_ec2_sg_id" {
  description = "EC2 security group ID — exported for reference and cross-region troubleshooting"
  value       = aws_security_group.tokyo_ec2_sg.id
}


# TGW — populated after tgw.tf is applied in Phase 2
# These outputs will be empty until tgw.tf resources exist.
# São Paulo depends on these — do not apply São Paulo until Phase 2 is complete.
output "tokyo_tgw_id" {
  description = "Tokyo Transit Gateway ID — São Paulo needs this to create the peering accepter"
  value       = try(aws_ec2_transit_gateway.tokyo_tgw.id, "")
}

output "tokyo_tgw_peering_attachment_id" {
  description = "TGW peering attachment ID initiated from Tokyo — São Paulo uses this to accept the peering"
  value       = aws_ec2_transit_gateway_peering_attachment.tokyo_to_sao_paulo.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name — global entry point"
  value       = aws_cloudfront_distribution.lab3_cf.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.lab3_cf.id
}

output "waf_acl_arn" {
  description = "WAF WebACL ARN — attached to CloudFront distribution"
  value       = aws_wafv2_web_acl.lab3_waf.arn
}
