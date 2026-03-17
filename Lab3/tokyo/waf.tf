# =============================================================================
# LAB 3 — WAF CONFIGURATION
# File: lab3/tokyo/waf.tf
# Provider: aws.useast1 (us-east-1) — required by AWS for CloudFront WAF
#
# PURPOSE:
#   WAF sits at the CloudFront edge and inspects every inbound request
#   before it reaches the Tokyo origin. This is the application-layer
#   security control that security groups cannot provide — SGs operate
#   at the network layer and cannot inspect HTTP payloads.
#
# WHY WAF MATTERS FOR APPI COMPLIANCE:
#   APPI requires adequate security controls, not just data residency.
#   WAF provides defense-in-depth: edge → ALB SG → RDS SG.
#   Without WAF, the edge is unprotected against web-layer attacks.
#
# RULE GROUPS DEPLOYED:
#   1. AWSManagedRulesCommonRuleSet — OWASP Top 10 protection
#      Blocks: SQL injection, XSS, path traversal, malformed requests
#   2. AWSManagedRulesAmazonIpReputationList — known bad actors
#      Blocks: requests from IPs AWS has flagged as malicious,
#              bots, scrapers, known attack infrastructure
#
# SCOPE: CLOUDFRONT
#   WAF scope must be CLOUDFRONT for distributions — not REGIONAL.
#   REGIONAL WAF cannot attach to CloudFront. This is why the
#   us-east-1 provider alias is required.
# =============================================================================

resource "aws_wafv2_web_acl" "lab3_waf" {
  provider = aws.useast1

  name        = "${var.project}-waf-acl"
  description = "WAF for Lab3 CloudFront - APPI healthcare edge protection"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }


# =============================================================================
#removed RequireCloudFrontSecret rule block 
# =============================================================================

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
      metric_name                = "${var.project}-common-rules"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-ip-reputation"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-waf-acl"
    sampled_requests_enabled   = true
  }

  tags = {
    Name       = "${var.project}-waf-acl"
    RegionRole = "edge-security"
    DataPolicy = "phi-japan-only"
  }
}

# -----------------------------------------------------------------------------
# REGIONAL WAF — ALB origin cloaking (Tokyo, ap-northeast-1)
# CloudFront adds x-cloudfront-secret when forwarding to the origin; the
# viewer never sends it. So the secret check must run here, on requests
# reaching the ALB — not on the CloudFront-scope WAF.
# -----------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "lab3_alb_waf" {
  name        = "${var.project}-alb-waf"
  description = "ALB level WAF enforces CloudFront origin secret blocks direct ALB access"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "RequireCloudFrontSecret"
    priority = 0

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          byte_match_statement {
            search_string = "Sao Paulo living tokyo dreaming"

            field_to_match {
              single_header {
                name = "x-cloudfront-secret"
              }
            }

            text_transformation {
              priority = 0
              type     = "NONE"
            }

            positional_constraint = "EXACTLY"
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-alb-waf"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-alb-waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name       = "${var.project}-alb-waf"
    RegionRole = "alb-protection"
    DataPolicy = "phi-japan-only"
  }
}

resource "aws_wafv2_web_acl_association" "lab3_alb_waf_assoc" {
  resource_arn = aws_lb.tokyo_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.lab3_alb_waf.arn
}
