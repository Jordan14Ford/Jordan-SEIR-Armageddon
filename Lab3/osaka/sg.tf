# osaka security groups

# ALB SG - allows HTTP from internet
resource "aws_security_group" "osaka_alb_sg" {
  name        = "${var.project}-osaka-alb-sg"
  description = "ALB security group"
  vpc_id      = aws_vpc.osaka_vpc.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-osaka-alb-sg"
  }
}

# EC2 SG - allows traffic from ALB and outbound for TGW
resource "aws_security_group" "osaka_ec2_sg" {
  name        = "${var.project}-osaka-ec2-sg"
  description = "EC2 app security group"
  vpc_id      = aws_vpc.osaka_vpc.id

  ingress {
    description     = "Flask from ALB"
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.osaka_alb_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-osaka-ec2-sg"
  }
}
