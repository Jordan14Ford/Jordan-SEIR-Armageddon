# S3 bucket for ALB access logs
resource "aws_s3_bucket" "cloudyjones_alb_logs_bucket01" {
  bucket        = "${var.project}-alb-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project}-alb-logs-bucket01"
    Project = var.project
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "cloudyjones_alb_logs_block" {
  bucket                  = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Required bucket policy for ALB to write logs
resource "aws_s3_bucket_policy" "cloudyjones_alb_logs_policy" {
  bucket = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = "arn:aws:iam::127311923021:root"
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudyjones_alb_logs_bucket01.arn}/alb-access-logs/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}