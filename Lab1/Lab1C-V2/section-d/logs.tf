# Bonus-D — ALB access logs → S3 + apex DNS record
# S3 bucket created here; its name is passed to section-b so the ALB can write to it

resource "aws_s3_bucket" "cloudyjones_alb_logs_bucket01" {
  bucket        = "${var.project}-alb-logs-${var.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project}-alb-logs-bucket01"
    Project = var.project
  }
}

resource "aws_s3_bucket_public_access_block" "cloudyjones_alb_logs_block" {
  bucket                  = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 127311923021 is the AWS ELB service account for us-east-1
# this ID differs per region — update if deploying elsewhere
resource "aws_s3_bucket_policy" "cloudyjones_alb_logs_policy" {
  bucket = aws_s3_bucket.cloudyjones_alb_logs_bucket01.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::127311923021:root" }
      Action    = "s3:PutObject"
      Resource  = "${aws_s3_bucket.cloudyjones_alb_logs_bucket01.arn}/alb-access-logs/AWSLogs/${var.account_id}/*"
    }]
  })
}

# Apex record: cloudyjones.xyz → ALB (ALIAS, not CNAME — required for apex domains)
resource "aws_route53_record" "cloudyjones_apex_alias01" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
