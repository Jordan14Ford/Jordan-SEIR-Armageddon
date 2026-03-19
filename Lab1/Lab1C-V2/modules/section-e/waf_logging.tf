# Bonus-E — WAF logging to CloudWatch Logs
# log group name MUST start with "aws-waf-logs-" — WAF rejects any other prefix

resource "aws_cloudwatch_log_group" "cloudyjones_waf_log_group01" {
  name              = "aws-waf-logs-${var.project}-webacl01"
  retention_in_days = 14

  tags = {
    Name    = "aws-waf-logs-${var.project}-webacl01"
    Project = var.project
  }
}

# Wire the WAF ACL to the log group — every request WAF inspects appears here
resource "aws_wafv2_web_acl_logging_configuration" "cloudyjones_waf_logging01" {
  log_destination_configs = [aws_cloudwatch_log_group.cloudyjones_waf_log_group01.arn]
  resource_arn            = var.waf_arn
}
