output "alb_logs_bucket_name" { value = aws_s3_bucket.cloudyjones_alb_logs_bucket01.bucket }
output "alb_logs_bucket_arn"  { value = aws_s3_bucket.cloudyjones_alb_logs_bucket01.arn }
output "apex_url_https"       { value = "https://${var.domain_name}" }
