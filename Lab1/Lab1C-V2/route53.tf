# ============================================================
# route53.tf — DNS, ACM certificate, and HTTPS listener
#
# flow: domain purchased on Namecheap → nameservers delegated
# to Route53 → ACM validates via DNS → cert issued → HTTPS works
#
# note: terraform apply will hang on the validation resource
# until you update nameservers in Namecheap. that's expected.
# ============================================================

# hosted zone — Route53 takes over DNS for cloudyjones.xyz
# after apply, grab the 4 nameservers and put them in Namecheap
resource "aws_route53_zone" "cloudyjones_zone01" {
  name = var.domain_name

  tags = {
    Name    = "${var.project}-zone01"
    Project = var.project
  }
}

# ACM cert — covers both the apex and app subdomain
# DNS validation means ACM creates a CNAME record to prove ownership
# much easier than email validation
resource "aws_acm_certificate" "cloudyjones_acm_cert01" {
  domain_name               = var.domain_name
  subject_alternative_names = ["${var.app_subdomain}.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    # create new cert before destroying old one
    # avoids downtime if you ever need to replace it
    create_before_destroy = true
  }

  tags = {
    Name    = "${var.project}-acm-cert01"
    Project = var.project
  }
}

# DNS validation records — ACM gives you CNAME records to add to Route53
# using for_each because the cert covers multiple domains
# Terraform creates these automatically so you don't have to do it manually
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

# this resource just waits for ACM to confirm the cert is ISSUED
# it will sit here until DNS propagates after nameserver update
# took about 45 min the first time due to Namecheap propagation delay
resource "aws_acm_certificate_validation" "cloudyjones_acm_validation01_dns_bonus" {
  certificate_arn         = aws_acm_certificate.cloudyjones_acm_cert01.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudyjones_acm_validation : record.fqdn]
}

# app subdomain record — app.cloudyjones.xyz points to ALB
# using ALIAS instead of CNAME because it works on apex domains
# and doesn't cost extra for Route53 queries
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

# apex record — cloudyjones.xyz also points to ALB
# can't use CNAME on apex domain, ALIAS is the AWS-specific solution
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

# HTTPS listener — TLS terminates at the ALB, not at EC2
# using TLS 1.3 policy, older clients may not connect but that's fine for a lab
# depends_on ensures cert is issued before this listener gets created
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