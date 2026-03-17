output "vpc_id" {
  value = aws_vpc.cloudyjones_vpc01.id
}

output "private_ec2_instance_id" {
  value = aws_instance.cloudyjones_ec201_private.id
}

output "rds_endpoint" {
  value = aws_db_instance.cloudyjones_rds01.address
}

output "rds_port" {
  value = aws_db_instance.cloudyjones_rds01.port
}

output "db_secret_name" {
  value = aws_secretsmanager_secret.cloudyjones_db_secret01.name
}

output "db_alarm_name" {
  value = aws_cloudwatch_metric_alarm.cloudyjones_db_connection_failure_alarm01.alarm_name
}

output "sns_topic_arn" {
  value = aws_sns_topic.cloudyjones_sns_topic01.arn
}

output "app_log_group_name" {
  value = aws_cloudwatch_log_group.cloudyjones_app_log_group01.name
}

output "waf_log_group_name" {
  value = aws_cloudwatch_log_group.cloudyjones_waf_log_group01.name
}

output "ir_reports_bucket" {
  value = aws_s3_bucket.cloudyjones_ir_reports_bucket01.bucket
}

output "alb_dns_name" {
  value = aws_lb.cloudyjones_alb01.dns_name
}

output "app_url" {
  value = "https://${var.app_subdomain}.${var.domain_name}"
}

output "apex_url" {
  value = "https://${var.domain_name}"
}

output "alb_logs_bucket" {
  value = aws_s3_bucket.cloudyjones_alb_logs_bucket01.bucket
}

output "route53_zone_id" {
  value = aws_route53_zone.cloudyjones_zone01.zone_id
}

output "route53_nameservers" {
  value = aws_route53_zone.cloudyjones_zone01.name_servers
}

output "monitoring_endpoint_id" {
  value = aws_vpc_endpoint.cloudyjones_monitoring.id
}
