# Data source to get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Private EC2 Instance
resource "aws_instance" "lab1c_private_ec2" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"

  # CRITICAL: Private subnet
  subnet_id = aws_subnet.private_2a.id

  # CRITICAL: No public IP
  associate_public_ip_address = false

  # CRITICAL: Attach IAM role
  iam_instance_profile = aws_iam_instance_profile.lab1c_ec2_profile.name

  # Security group
  vpc_security_group_ids = [aws_security_group.lab1c_private_ec2_sg.id]

  # Optional: User data for basic setup
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y amazon-cloudwatch-agent
              EOF

  # Root volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true

    tags = {
      Name = "lab1c-private-ec2-root"
    }
  }

  tags = {
    Name        = "lab1c-private-ec2"
    Environment = "lab1c"
    Phase       = "phase2"
  }
}

# Output the instance ID for easy SSM access
output "private_ec2_instance_id" {
  description = "Instance ID for SSM Session Manager"
  value       = aws_instance.lab1c_private_ec2.id
}

output "private_ec2_private_ip" {
  description = "Private IP address of EC2 instance"
  value       = aws_instance.lab1c_private_ec2.private_ip
}