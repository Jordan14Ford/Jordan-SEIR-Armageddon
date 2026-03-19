# data.tf
# i'm not creating these resources here — they already exist from the foundation lab
# i'm just pulling them in so i can reference them in this lab
# think of data blocks as "read only" lookups into AWS

# grab the ALB by name so i can reference its ARN elsewhere
data "aws_lb" "cloudyjones_alb01" {
  name = "${var.project}-alb01"
}

# grab the HTTPS listener on the ALB — i need this to add the
# secret header rule that checks for X-Chewbacca-Growl
data "aws_lb_listener" "cloudyjones_https" {
  load_balancer_arn = data.aws_lb.cloudyjones_alb01.arn
  port              = 443
}

# grab the ALB security group so i can tighten it up
# goal is to only allow traffic from cloudfront IPs, not the open internet
data "aws_security_group" "cloudyjones_alb_sg01" {
  name = "${var.project}-alb-sg01"
}

# grab the route 53 hosted zone so i can update the A records
# to point at cloudfront instead of directly at the ALB
data "aws_route53_zone" "cloudyjones_zone01" {
  name         = var.domain_name
  private_zone = false
}

# grab the ACM cert — cloudfront uses this for HTTPS on the viewer side
# has to use the us_east_1 provider because cloudfront only accepts
# certs that live in us-east-1
data "aws_acm_certificate" "cloudyjones_cert" {
  domain      = var.domain_name
  statuses    = ["ISSUED"]
  most_recent = true
  provider    = aws.us_east_1
}
