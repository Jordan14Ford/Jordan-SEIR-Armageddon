# CloudWatch log group for WAF — must start with aws-waf-logs-
resource "aws_cloudwatch_log_group" "cloudyjones_waf_log_group01" {
  name              = "aws-waf-logs-${var.project}-webacl01"
  retention_in_days = 14

  tags = {
    Name    = "aws-waf-logs-${var.project}-webacl01"
    Project = var.project
  }
}

# WAF logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "cloudyjones_waf_logging01" {
  log_destination_configs = [aws_cloudwatch_log_group.cloudyjones_waf_log_group01.arn]
  resource_arn            = aws_wafv2_web_acl.cloudyjones_waf01.arn
}