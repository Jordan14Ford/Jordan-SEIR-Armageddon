# Security Group for Private EC2
resource "aws_security_group" "lab1c_private_ec2_sg" {
  name        = "lab1c-private-ec2-sg"
  description = "Security group for private EC2 - SSM only"
  vpc_id      = aws_vpc.lab1c.id

  # NO INBOUND RULES - SSM doesn't need them

  # Outbound: Allow HTTPS to reach VPC endpoints
  egress {
    description = "Allow HTTPS outbound for VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "lab1c-private-ec2-sg"
    Environment = "lab1c"
    Phase       = "phase2"
  }
}