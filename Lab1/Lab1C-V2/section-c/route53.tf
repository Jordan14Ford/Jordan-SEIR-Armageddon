# Bonus-C — Route53 hosted zone, ACM certificate, DNS validation, HTTPS listener
# flow: Namecheap nameservers → Route53 → ACM validates via CNAME → cert issued → HTTPS works

resource "aws_route53_zone" "cloudyjones_zone01" {
  name = var.domain_name

  tags = {
    Name    = "${var.project}-zone01"
    Project = var.project
  }
}

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

resource "aws_acm_certificate_validation" "cloudyjones_acm_validation01_dns_bonus" {
  certificate_arn         = aws_acm_certificate.cloudyjones_acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudyjones_acm_validation : record.fqdn]
}

# app.cloudyjones.xyz → ALB
resource "aws_route53_record" "cloudyjones_app_alias01" {
  zone_id = aws_route53_zone.cloudyjones_zone01.zone_id
  name    = "${var.app_subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# HTTPS listener — TLS terminates at ALB, depends_on ensures cert is ISSUED first
resource "aws_lb_listener" "cloudyjones_https_listener01" {
  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.cloudyjones_acm_cert01.arn

  default_action {
    type             = "forward"
    target_group_arn = var.tg_arn
  }

  depends_on = [aws_acm_certificate_validation.cloudyjones_acm_validation01_dns_bonus]
}
