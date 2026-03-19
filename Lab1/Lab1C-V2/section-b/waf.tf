# Bonus-B — WAF Web ACL attached to ALB
# REGIONAL scope because it's attached to an ALB (not CloudFront)
# default action ALLOW — managed rules handle specific blocking

resource "aws_wafv2_web_acl" "cloudyjones_waf01" {
  name        = "${var.project}-webacl01"
  description = "WAF Web ACL for ${var.project} ALB"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

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

# Attach WAF to ALB — without this the ACL exists but inspects nothing
resource "aws_wafv2_web_acl_association" "cloudyjones_waf_alb01" {
  resource_arn = aws_lb.cloudyjones_alb01.arn
  web_acl_arn  = aws_wafv2_web_acl.cloudyjones_waf01.arn
}
