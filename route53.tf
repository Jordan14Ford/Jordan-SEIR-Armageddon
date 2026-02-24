# Route53 Hosted Zone for cloudyjones.xyz
resource "aws_route53_zone" "cloudyjones_zone01" {
  name = var.domain_name

  tags = {
    Name    = "${var.project}-zone01"
    Project = var.project
  }
}

# ACM Certificate for app.cloudyjones.xyz and cloudyjones.xyz
resource "aws_acm_certificate" "cloudyjones_acm_cert01" {
  domain_name               = var.domain_name
  subject_alternative_names = ["${var.app_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.project}-acm-cert01"
    Project = var.project
  }
}

# DNS validation records — proves you own the domain
resource "aws_route53_record" "cloudyjones_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cloudyjones_acm_cert01.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.cloudyjones_zone01.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# ACM validation — waits for cert to be issued
resource "aws_acm_certificate_validation" "cloudyjones_acm_validation01_dns_bonus" {
  certificate_arn         = aws_acm_certificate.cloudyjones_acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudyjones_acm_validation : record.fqdn]
}

# ALIAS record — app.cloudyjones.xyz -> ALB
resource "aws_route53_record" "cloudyjones_app_alias01" {
  zone_id = aws_route53_zone.cloudyjones_zone01.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.cloudyjones_alb01.dns_name
    zone_id                = aws_lb.cloudyjones_alb01.zone_id
    evaluate_target_health = true
  }
}

# ALIAS record — cloudyjones.xyz apex -> ALB
resource "aws_route53_record" "cloudyjones_apex_alias01" {
  zone_id = aws_route53_zone.cloudyjones_zone01.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.cloudyjones_alb01.dns_name
    zone_id                = aws_lb.cloudyjones_alb01.zone_id
    evaluate_target_health = true
  }
}

# HTTPS listener — TLS terminates here, forwards to private EC2
resource "aws_lb_listener" "cloudyjones_https_listener01" {
  load_balancer_arn = aws_lb.cloudyjones_alb01.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cloudyjones_acm_cert01.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cloudyjones_tg01.arn
  }

  depends_on = [aws_acm_certificate_validation.cloudyjones_acm_validation01_dns_bonus]
}