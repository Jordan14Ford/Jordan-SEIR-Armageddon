output "alb_arn"        { value = aws_lb.cloudyjones_alb01.arn }
output "alb_dns_name"   { value = aws_lb.cloudyjones_alb01.dns_name }
output "alb_zone_id"    { value = aws_lb.cloudyjones_alb01.zone_id }
output "alb_arn_suffix" { value = aws_lb.cloudyjones_alb01.arn_suffix }
output "tg_arn"         { value = aws_lb_target_group.cloudyjones_tg01.arn }
output "alb_sg_id"      { value = aws_security_group.cloudyjones_alb_sg01.id }
output "waf_arn"        { value = aws_wafv2_web_acl.cloudyjones_waf01.arn }
