resource "aws_security_group" "lab1c_rds_sg" {
  name        = "lab1c-rds-sg"
  description = "RDS MySQL from EC2 only"
  vpc_id      = aws_vpc.lab1c.id

  ingress {
    description     = "MySQL from EC2"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.lab1c_private_ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lab1c-rds-sg"
  }
}