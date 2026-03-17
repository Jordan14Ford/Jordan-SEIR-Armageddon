# =============================================================================
# LAB 3 — CLOUDFRONT DISTRIBUTION
# Provider: aws.useast1 (us-east-1) — CloudFront
#
# PURPOSE:
#   CloudFront is the single global entry point for the Lab 3 healthcare
#   architecture. All requests from any region hit CloudFront first,
#   then route to the Tokyo ALB (the sole origin).
#
# ORIGIN DECISION — TOKYO ONLY:
#   Tokyo is the sole CloudFront origin. São Paulo is stateless compute
#   and has no data authority — it does not need to be a CloudFront origin.
#   Using a single origin keeps the compliance narrative clean: one path
#   in, one data authority, one jurisdiction. Latency optimization via
#   multi-origin was considered and rejected because compliance clarity
#   outweighs latency gains in a regulated healthcare system.
#   See DECISIONS.md for full tradeoff reasoning.
#
# ORIGIN CLOAKING:
#   A custom header "X-CloudFront-Secret" is injected on every request
#   to the origin. The Tokyo ALB security group only accepts traffic
#   containing this header. This prevents anyone from bypassing CloudFront
#   and hitting the ALB directly — the origin is cloaked behind the CDN.
#   Header value: "Sao Paulo living tokyo dreaming"
#
# CACHING:
#   Dynamic content must NOT be cached. PHI responses must never be
#   stored at CloudFront edge nodes — edge nodes are outside Japan and
#   caching PHI there would violate APPI. Cache is disabled via
#   CachingDisabled policy.
#
# WAF:
#   WAF WebACL (from waf.tf) is attached to this distribution.
#   All requests are inspected before reaching the origin.
# =============================================================================

locals {
  # Origin cloaking secret — injected as a custom header on every request
  # to the Tokyo ALB. Prevents direct ALB access bypassing CloudFront and WAF.
  cloudfront_secret = "Sao Paulo living tokyo dreaming"
}

resource "aws_cloudfront_distribution" "lab3_cf" {
  provider = aws.useast1

  origin {
    domain_name = aws_lb.tokyo_alb.dns_name
    origin_id   = "tokyo-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
# =============================================================================
# changed phrase here 
# =============================================================================
    custom_header {
      name  = "x-cloudfront-secret"
      value = "Sao Paulo living tokyo dreaming"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Lab3 global entry point — APPI healthcare architecture"
  default_root_object = ""

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "tokyo-alb-origin"

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

    viewer_protocol_policy = "allow-all"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  web_acl_id = aws_wafv2_web_acl.lab3_waf.arn

  price_class = "PriceClass_100"

  tags = {
    Name       = "${var.project}-cloudfront"
    RegionRole = "global-edge"
    DataPolicy = "phi-japan-only"
  }

  depends_on = [aws_wafv2_web_acl.lab3_waf]
}
