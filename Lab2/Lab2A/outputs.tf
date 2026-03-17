#will  need to update outputs file to reflect 
# values terraform prints after a successful apply
# useful for grabbing ARNs/IDs i need for testing or future labs
# without having to dig through the AWS console

# the cloudfront domain name — use this to test before DNS cuts over
# hit this directly in the browser to confirm cloudfront is working
output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cloudyjones_cf01.domain_name
}

# need this ID any time i want to run a cache invalidation
# e.g. aws cloudfront create-invalidation --distribution-id <this> --paths "/*"
output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed for invalidations"
  value       = aws_cloudfront_distribution.cloudyjones_cf01.id
}

# after lockdown i should be able to curl this directly and get a 403
# if i get a 200 back then the SG or listener rules aren't set up right
output "alb_dns" {
  description = "ALB DNS name — direct access should return 403 after lockdown"
  value       = data.aws_lb.cloudyjones_alb01.dns_name
}

# the WAF ARN — useful if i need to reference it in another config
# or check it in the AWS console under WAF & Shield
output "waf_arn" {
  description = "CloudFront WAF ARN"
  value       = aws_wafv2_web_acl.cloudyjones_cf_waf01.arn
}

# Route 53 hosted zone ID — for verification script (list record sets)
output "hosted_zone_id" {
  description = "Route 53 hosted zone ID for the domain"
  value       = data.aws_route53_zone.cloudyjones_zone01.zone_id
}
