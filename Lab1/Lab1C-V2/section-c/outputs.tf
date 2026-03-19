output "zone_id"       { value = aws_route53_zone.cloudyjones_zone01.zone_id }
output "nameservers"   { value = aws_route53_zone.cloudyjones_zone01.name_servers }
output "cert_arn"      { value = aws_acm_certificate.cloudyjones_acm_cert01.arn }
output "app_url_https" { value = "https://${var.app_subdomain}.${var.domain_name}" }
