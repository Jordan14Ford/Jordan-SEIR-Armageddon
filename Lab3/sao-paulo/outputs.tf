# =============================================================================
# LAB 3 - SAO PAULO OUTPUTS
# File: lab3/sao-paulo/outputs.tf
# Region: sa-east-1 (Sao Paulo)
# Purpose: Exports key values from the Sao Paulo state for reference and
#          for Tokyo to consume when completing the TGW peering.
#
# WHO USES THESE OUTPUTS:
#   - Tokyo may reference sao_paulo_tgw_id to complete peering setup
#   - You (the student) reference these when verifying connectivity
#   - Audit scripts may query these for compliance checks
# =============================================================================


# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

output "sao_paulo_vpc_id" {
  description = "Sao Paulo VPC ID"
  value       = aws_vpc.sao_paulo_vpc.id
}

output "sao_paulo_vpc_cidr" {
  description = "Sao Paulo VPC CIDR (10.1.0.0/16)"
  value       = aws_vpc.sao_paulo_vpc.cidr_block
}

output "sao_paulo_private_subnet_1_id" {
  description = "Sao Paulo private subnet 1 (sa-east-1a)"
  value       = aws_subnet.sao_paulo_private_1.id
}

output "sao_paulo_private_subnet_2_id" {
  description = "Sao Paulo private subnet 2 (sa-east-1b)"
  value       = aws_subnet.sao_paulo_private_2.id
}

output "sao_paulo_private_route_table_id" {
  description = "Sao Paulo private route table ID"
  value       = aws_route_table.sao_paulo_private_rt.id
}


# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

output "sao_paulo_alb_dns" {
  description = "Sao Paulo ALB DNS name - use this to test the app tier"
  value       = aws_lb.sao_paulo_alb.dns_name
}


# -----------------------------------------------------------------------------
# SECURITY GROUPS
# -----------------------------------------------------------------------------

output "sao_paulo_ec2_sg_id" {
  description = "EC2 security group ID"
  value       = aws_security_group.sao_paulo_ec2_sg.id
}

output "sao_paulo_alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.sao_paulo_alb_sg.id
}


# -----------------------------------------------------------------------------
# TRANSIT GATEWAY
# These are the values Tokyo needs to complete the peering setup.
# -----------------------------------------------------------------------------

output "sao_paulo_tgw_id" {
  description = "Sao Paulo Transit Gateway ID - Tokyo needs this to initiate peering"
  value       = aws_ec2_transit_gateway.sao_paulo_tgw.id
}

output "sao_paulo_tgw_route_table_id" {
  description = "Sao Paulo TGW default route table ID"
  value       = aws_ec2_transit_gateway.sao_paulo_tgw.association_default_route_table_id
}


# -----------------------------------------------------------------------------
# EC2 INSTANCE
# -----------------------------------------------------------------------------

output "sao_paulo_app_instance_id" {
  description = "Sao Paulo Flask app EC2 instance ID"
  value       = aws_instance.sao_paulo_app.id
}

output "sao_paulo_app_private_ip" {
  description = "Sao Paulo Flask app private IP address"
  value       = aws_instance.sao_paulo_app.private_ip
}


# -----------------------------------------------------------------------------
# TOKYO REFERENCES (read from remote state, echoed for convenience)
# -----------------------------------------------------------------------------

output "tokyo_rds_endpoint_used" {
  description = "The Tokyo RDS endpoint this Flask app connects to"
  value       = data.terraform_remote_state.tokyo.outputs.tokyo_rds_endpoint
}
