# lab2_cloudfront_alb.tf

resource "aws_cloudfront_distribution" "cloudyjones_cf01" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project} CloudFront distribution"
  default_root_object = ""

  # the ALB is my origin — cloudfront proxies back to it
  origin {
    domain_name = data.aws_lb.cloudyjones_alb01.dns_name
    origin_id   = "${var.project}-alb-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    # layer 2 of origin cloaking
    # cloudfront stamps this header on every request it sends to the ALB
    # the ALB listener rule checks for it — no header = 403
    custom_header {
      name  = "X-Chewbacca-Growl"
      value = var.origin_secret
    }
  }

  aliases = [
    var.domain_name,
    "app.${var.domain_name}"
  ]

  # ordered behavior 1: /api/public-feed — origin-driven caching (Honors A)
  # must be listed before /api/* or it will never match
  ordered_cache_behavior {
    path_pattern           = "/api/public-feed"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = local.use_origin_cache_control_headers_policy_id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.cloudyjones_api_orp.id
  }

  # ordered behavior 2: /api/* — caching disabled
  # every request passes through to origin
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.cloudyjones_api_cp.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.cloudyjones_api_orp.id
  }

  # ordered behavior 3: /static/* — aggressive caching
  # cache key is path only, query strings stripped
  # Be A Man: response headers policy adds explicit Cache-Control for static
  ordered_cache_behavior {
    path_pattern           = "/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id            = aws_cloudfront_cache_policy.cloudyjones_static_cp.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.cloudyjones_static_orp.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.cloudyjones_static_rhp.id
  }

  # default cache behavior — caching off, everything forwarded to ALB
  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.project}-alb-origin"
    viewer_protocol_policy = "redirect-to-https"

    # CachingDisabled managed policy
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # AllViewerExceptHostHeader
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  viewer_certificate {
    acm_certificate_arn      = data.aws_acm_certificate.cloudyjones_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  web_acl_id = aws_wafv2_web_acl.cloudyjones_cf_waf01.arn

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name    = "${var.project}-cf01"
    Project = var.project
  }
}
