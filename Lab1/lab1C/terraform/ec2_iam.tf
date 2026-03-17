# IAM Role for EC2 - allows EC2 service to assume this role
resource "aws_iam_role" "lab1c_ec2_role" {
  name = "lab1c-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "lab1c-ec2-ssm-role"
    Environment = "lab1c"
    Phase       = "phase2"
  }
}

# Attach AWS managed policy for SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.lab1c_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach AWS managed policy for CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.lab1c_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Attach AWS managed policy for Secrets Manager
resource "aws_iam_role_policy_attachment" "secrets_policy" {
  role       = aws_iam_role.lab1c_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Instance Profile - this is what actually attaches to EC2
resource "aws_iam_instance_profile" "lab1c_ec2_profile" {
  name = "lab1c-ec2-instance-profile"
  role = aws_iam_role.lab1c_ec2_role.name

  tags = {
    Name        = "lab1c-ec2-instance-profile"
    Environment = "lab1c"
    Phase       = "phase2"
  }
}