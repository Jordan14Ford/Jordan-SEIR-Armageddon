# ============================================================
# waf_logging.tf — WAF log shipping to CloudWatch
#
# WAF can log every request it inspects (allowed and blocked)
# useful for the Section F Logs Insights queries
#
# important: log group name MUST start with "aws-waf-logs-"
# WAF will reject any other prefix — learned this from the docs
# ============================================================

# CloudWatch log group for WAF logs
# retention set to 14 days to keep costs down
# logs older than 14 days are automatically deleted
resource "aws_cloudwatch_log_group" "cloudyjones_waf_log_group01" {
  name              = "aws-waf-logs-${var.project}-webacl01"
  retention_in_days = 14

  tags = {
    Name    = "aws-waf-logs-${var.project}-webacl01"
    Project = var.project
  }
}

# wire the WAF Web ACL to the log group
# after this is applied, every request WAF inspects shows up in CloudWatch
# you can then run Logs Insights queries against it for incident analysis
resource "aws_wafv2_web_acl_logging_configuration" "cloudyjones_waf_logging01" {
  log_destination_configs = [aws_cloudwatch_log_group.cloudyjones_waf_log_group01.arn]
  resource_arn            = aws_wafv2_web_acl.cloudyjones_waf01.arn
}