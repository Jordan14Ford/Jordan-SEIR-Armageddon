# ============================================================
# logs.tf — S3 bucket for ALB access logs
#
# ALB can ship every request log to S3 automatically
# useful for debugging, auditing, and the Section F queries
# ============================================================

# S3 bucket — name includes account ID to make it globally unique
# force_destroy = true so terraform destroy doesn't fail if bucket has objects
resource "aws_s3_bucket" "cloudyjones_alb_logs_bucket01" {
  bucket        = "${var.project}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project}-alb-logs-bucket01"
    Project = var.project
  }
}

# block all public access — logs should never be publicly readable
resource "aws_s3_bucket_public_access_block" "cloudyjones_alb_logs_block" {
  bucket                  = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# bucket policy — grants the ALB service account permission to write logs
# 127311923021 is the AWS-owned account for ELB in us-east-1
# this account ID is different per region — us-east-1 specific
# without this policy, ALB silently fails to write logs
resource "aws_s3_bucket_policy" "cloudyjones_alb_logs_policy" {
  bucket = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudyjones_alb_logs_bucket01.arn}/alb-access-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

# data source — pulls current AWS account ID dynamically
# used in bucket name and bucket policy above
data "aws_caller_identity" "current" {}