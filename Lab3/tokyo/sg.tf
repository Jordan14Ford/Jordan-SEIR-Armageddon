# security groups
# had to split into separate rule resources to avoid cycle errors
resource "aws_security_group" "tokyo_alb_sg" {
  name        = "${var.project}-tokyo-alb-sg"
  description = "Tokyo ALB security group"
  vpc_id      = aws_vpc.tokyo_vpc.id
  tags = { Name = "${var.project}-tokyo-alb-sg" }
}

resource "aws_security_group" "tokyo_ec2_sg" {
  name        = "${var.project}-tokyo-ec2-sg"
  description = "Tokyo EC2 app security group"
  vpc_id      = aws_vpc.tokyo_vpc.id
  tags = { Name = "${var.project}-tokyo-ec2-sg" }
}

resource "aws_security_group" "tokyo_rds_sg" {
  name        = "${var.project}-tokyo-rds-sg"
  description = "Tokyo RDS security group"
  vpc_id      = aws_vpc.tokyo_vpc.id
  tags = { Name = "${var.project}-tokyo-rds-sg" }
}

# ALB rules
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  security_group_id = aws_security_group.tokyo_alb_sg.id
  description       = "HTTP from internet"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  security_group_id = aws_security_group.tokyo_alb_sg.id
  description       = "HTTPS from internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress_to_ec2" {
  type                     = "egress"
  security_group_id        = aws_security_group.tokyo_alb_sg.id
  description              = "Forward to Flask on EC2"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tokyo_ec2_sg.id
}

# EC2 rules
resource "aws_security_group_rule" "ec2_ingress_from_alb" {
  type                     = "ingress"
  security_group_id        = aws_security_group.tokyo_ec2_sg.id
  description              = "Flask port from ALB only"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tokyo_alb_sg.id
}

resource "aws_security_group_rule" "ec2_egress_to_rds" {
  type                     = "egress"
  security_group_id        = aws_security_group.tokyo_ec2_sg.id
  description              = "MySQL to RDS"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tokyo_rds_sg.id
}

# need this for SSM and pip to work
resource "aws_security_group_rule" "ec2_egress_https" {
  type              = "egress"
  security_group_id = aws_security_group.tokyo_ec2_sg.id
  description       = "HTTPS outbound for SSM, CloudWatch, Secrets Manager"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

# RDS rules
resource "aws_security_group_rule" "rds_ingress_from_ec2" {
  type                     = "ingress"
  security_group_id        = aws_security_group.tokyo_rds_sg.id
  description              = "MySQL from Tokyo EC2"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.tokyo_ec2_sg.id
}

# this lets sao paulo connect - don't forget this!
resource "aws_security_group_rule" "rds_ingress_from_sao_paulo" {
  type              = "ingress"
  security_group_id = aws_security_group.tokyo_rds_sg.id
  description       = "MySQL from Sao Paulo VPC via TGW"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.sao_paulo_vpc_cidr] # 10.1.0.0/16
}

# osaka failover region
resource "aws_security_group_rule" "rds_ingress_from_osaka" {
  type              = "ingress"
  security_group_id = aws_security_group.tokyo_rds_sg.id
  description       = "MySQL from Osaka VPC via TGW (failover)"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = [var.osaka_vpc_cidr] # 10.2.0.0/16
}
