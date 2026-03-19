# lab2_cloudfront_shield_waf.tf
# creates a new WAF at CLOUDFRONT scope in us-east-1
# this replaces the regional WAF that was attached directly to the ALB
# by moving WAF to the edge, rules run at cloudfront's global PoPs
# before traffic ever enters my VPC — way earlier in the chain

# has to use provider = aws.us_east_1 — AWS hard requires all
# CLOUDFRONT-scoped WAF resources to live in us-east-1
# doesnt matter what region the rest of my stack is in

resource "aws_wafv2_web_acl" "cloudyjones_cf_waf01" {
  provider    = aws.us_east_1
  name        = "${var.project}-cf-webacl01"
  description = "WAF for CloudFront distribution - CLOUDFRONT scope"
  scope       = "CLOUDFRONT"

  # default is to allow everything through
  # the rules below then block the bad stuff
  default_action {
    allow {}
  }

  # AWS managed rule set — catches the classic stuff
  # SQL injection, XSS, path traversal, etc
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # blocks known malicious patterns and inputs
  # things like log4j exploit strings, SSRF attempts, etc
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # top level visibility config — sends metrics to cloudwatch
  # so i can see whats being blocked in the console
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-cf-webacl01"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "${var.project}-cf-webacl01"
    Project = var.project
  }
}
