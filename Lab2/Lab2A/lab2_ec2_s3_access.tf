# lab2_ec2_s3_access.tf
# adds s3 read permission to the EC2 role so we can use S3
# as a deployment artifact store for app updates
# scoped to the specific ALB logs bucket — least privilege

resource "aws_iam_role_policy" "cloudyjones_ec2_s3_read" {
  name = "cloudyjones-ec2-s3-read-lab2"
  role = "cloudyjones-ec2-role01"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowS3ReadForDeployments"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::cloudyjones-alb-logs-583001104385/*"
      }
    ]
  })
}
