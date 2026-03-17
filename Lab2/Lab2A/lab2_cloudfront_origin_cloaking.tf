# lab2_cloudfront_origin_cloaking.tf
# this file locks down the ALB so only cloudfront can reach it
# two layers of protection working together:
#
# layer 1 (network): swap the ALB security group ingress rule
# from 0.0.0.0/0 to only the cloudfront managed prefix list
# so random internet traffic gets dropped at the TCP level
# before it even touches the ALB listener
#
# layer 2 (application): add a listener rule that checks for
# the secret header — even if someone somehow gets through
# the SG by using their own cloudfront distro pointed at my ALB,
# they still wont have the right header and will get a 403

# AWS maintains this prefix list — its the list of IPs that
# cloudfront uses when connecting back to origins like my ALB
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# replaces the old open 0.0.0.0/0 HTTPS rule on the ALB SG
# using aws_security_group_rule so i don't have to blow away
# and recreate the whole security group
resource "aws_security_group_rule" "cloudyjones_alb_ingress_cf" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  prefix_list_ids   = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  security_group_id = data.aws_security_group.cloudyjones_alb_sg01.id
  description       = "HTTP from CloudFront origin-facing IPs only"
}


# need the target group ARN so the listener rule knows where to
# forward traffic when the secret header check passes
data "aws_lb_target_group" "cloudyjones_tg01" {
  name = "${var.project}-tg01"
}

# the actual header check rule — priority 1 so it runs first
# if X-Chewbacca-Growl matches the secret → forward to EC2
# if it doesnt match → falls through to the default 403 below
resource "aws_lb_listener_rule" "cloudyjones_secret_header" {
  listener_arn = data.aws_lb_listener.cloudyjones_https.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = data.aws_lb_target_group.cloudyjones_tg01.arn
  }

  condition {
    http_header {
      http_header_name = "X-Chewbacca-Growl"
      values           = [var.origin_secret]
    }
  }
}

# anything that doesnt match the rule above hits this
# returns a plain 403 Forbidden — no hints, no error details

