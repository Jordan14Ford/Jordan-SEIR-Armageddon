# VPC Endpoints Security Group (existing)
data "aws_security_group" "vpc_endpoints" {
  id = "sg-0316b266b03854859"
}

# EC2 Security Group (existing)
data "aws_security_group" "ec2" {
  id = "sg-065059717758785c4"
}

# RDS Security Group (existing)
data "aws_security_group" "rds" {
  id = "sg-092926e66455177b6"
}

output "security_group_vpc_endpoints_id" {
  description = "ID of VPC Endpoints security group"
  value       = data.aws_security_group.vpc_endpoints.id
}

output "security_group_ec2_id" {
  description = "ID of EC2 security group"
  value       = data.aws_security_group.ec2.id
}

output "security_group_rds_id" {
  description = "ID of RDS security group"
  value       = data.aws_security_group.rds.id
}