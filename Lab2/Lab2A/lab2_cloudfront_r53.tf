# lab2_cloudfront_r53.tf
# updates the A records that used to point at the ALB
# now they point at the cloudfront distribution instead
# users hit the same URLs — they just go through cloudfront now

# Z2FDTNDATAQYW2 is a fixed hosted zone ID that AWS uses for ALL
# cloudfront distributions — not specific to mine, its just how
# route 53 alias records to cloudfront work

# apex domain — cloudyjones.xyz
resource "aws_route53_record" "cloudyjones_apex_cf" {
  zone_id = data.aws_route53_zone.cloudyjones_zone01.zone_id
  allow_overwrite = true
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudyjones_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cloudyjones_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}

# app subdomain — app.cloudyjones.xyz
resource "aws_route53_record" "cloudyjones_app_cf" {
  zone_id = data.aws_route53_zone.cloudyjones_zone01.zone_id
  allow_overwrite = true
  name    = "app.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cloudyjones_cf01.domain_name
    zone_id                = aws_cloudfront_distribution.cloudyjones_cf01.hosted_zone_id
    evaluate_target_health = false
  }
}
