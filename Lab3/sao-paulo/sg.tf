# =============================================================================
# LAB 3 - SAO PAULO SECURITY GROUPS
# File: lab3/sao-paulo/sg.tf
# Region: sa-east-1 (Sao Paulo)
# Purpose: Defines security groups for the Sao Paulo compute tier.
#
# KEY DIFFERENCE FROM TOKYO:
#   - No RDS security group (no database in Sao Paulo)
#   - EC2 SG allows outbound to Tokyo CIDR on 3306 for RDS connectivity
#
# SECURITY GROUP LAYOUT:
#   1. ALB SG    - allows inbound HTTP/HTTPS from internet
#   2. EC2 SG    - allows inbound from ALB only, outbound to Tokyo RDS
#
# EGRESS TO TOKYO:
#   The EC2 security group explicitly allows outbound traffic to 10.0.0.0/16
#   on port 3306. This is the MySQL port. Traffic flows through the TGW
#   to reach the Tokyo RDS instance.
# =============================================================================


# -----------------------------------------------------------------------------
# ALB SECURITY GROUP
# Controls traffic to the Application Load Balancer.
# Allows HTTP (80) and HTTPS (443) from anywhere on the internet.
# This is the entry point for all user traffic to the Sao Paulo app tier.
# -----------------------------------------------------------------------------
resource "aws_security_group" "sao_paulo_alb_sg" {
  name        = "${var.project}-sao-paulo-alb-sg"
  description = "Allow HTTP and HTTPS traffic to the Sao Paulo ALB"
  vpc_id      = aws_vpc.sao_paulo_vpc.id

  # HTTP from anywhere
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS from anywhere
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound to EC2 instances (health checks and forwarding)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-sao-paulo-alb-sg"
  }
}


# -----------------------------------------------------------------------------
# EC2 SECURITY GROUP
# Controls traffic to the Flask app instances in private subnets.
#
# INBOUND:
#   - Port 5000 from ALB SG only (Flask default port)
#   - Port 22 from VPC CIDR (SSM fallback, should use SSM instead)
#
# OUTBOUND:
#   - Port 3306 to Tokyo CIDR (10.0.0.0/16) for RDS connectivity over TGW
#   - Port 443 to anywhere (SSM, pip installs, AWS API calls)
#   - Port 80 to anywhere (package downloads)
#
# WHY PORT 3306 TO TOKYO?
#   The Flask app on these EC2 instances connects to the RDS MySQL database
#   in Tokyo. That traffic crosses the TGW peering connection. The Tokyo RDS
#   security group must also allow inbound 3306 from 10.1.0.0/16 (Sao Paulo).
# -----------------------------------------------------------------------------
resource "aws_security_group" "sao_paulo_ec2_sg" {
  name        = "${var.project}-sao-paulo-ec2-sg"
  description = "Allow traffic to Sao Paulo EC2 app instances"
  vpc_id      = aws_vpc.sao_paulo_vpc.id

  # Flask app port from ALB only
  ingress {
    description     = "Flask from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.sao_paulo_alb_sg.id]
  }

  # SSH fallback from within VPC (prefer SSM)
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.sao_paulo_vpc_cidr]
  }

  # MySQL to Tokyo RDS over TGW
  egress {
    description = "MySQL to Tokyo RDS"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.tokyo_vpc_cidr]
  }

  # HTTPS outbound for SSM, pip, AWS APIs
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for package downloads
  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS outbound
  egress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-sao-paulo-ec2-sg"
  }
}
