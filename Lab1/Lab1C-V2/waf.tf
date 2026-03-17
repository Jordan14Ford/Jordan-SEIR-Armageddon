# ============================================================
# waf.tf — WAF Web ACL attached to the ALB
#
# WAF sits in front of the ALB and inspects every request
# before it reaches the target group. using AWS managed rule
# groups here instead of writing custom rules from scratch.
#
# default action is ALLOW — managed rules block specific threats
# ============================================================

# Web ACL — REGIONAL scope because it's attached to an ALB
# (CLOUDFRONT scope is for distributions, not ALBs)
resource "aws_wafv2_web_acl" "cloudyjones_waf01" {
  name        = "${var.project}-webacl01"
  description = "WAF Web ACL for cloudyjones ALB"
  scope       = "REGIONAL"

  # allow everything by default, rules below block specific threats
  default_action {
    allow {}
  }

  # rule 1: AWSManagedRulesCommonRuleSet
  # blocks common web exploits: XSS, SQLi, bad HTTP methods, etc.
  # this is the baseline rule set AWS recommends for most applications
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {} # use the rule group's own actions (block/count)
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

  # rule 2: AWSManagedRulesKnownBadInputsRuleSet
  # blocks requests with patterns known to be malicious
  # things like Log4j exploit attempts, SSRF patterns, etc.
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

  # top-level visibility config — enables WAF metrics in CloudWatch
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-webacl01"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "${var.project}-webacl01"
    Project = var.project
  }
}

# attach WAF to ALB — without this the Web ACL exists but does nothing
# one WAF can be attached to multiple resources if needed
resource "aws_wafv2_web_acl_association" "cloudyjones_waf_alb01" {
  resource_arn = aws_lb.cloudyjones_alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudyjones_waf01.arn
}