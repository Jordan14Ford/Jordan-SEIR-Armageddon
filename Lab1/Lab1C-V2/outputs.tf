# ── Core ────────────────────────────────────────────────────────
output "vpc_id"                { value = module.core.vpc_id }
output "private_ec2_instance_id" { value = module.core.ec2_instance_id }
output "rds_endpoint"          { value = module.core.rds_endpoint }
output "rds_port"              { value = module.core.rds_port }
output "db_secret_name"        { value = module.core.db_secret_name }
output "db_alarm_name"         { value = module.core.db_alarm_name }
output "sns_topic_arn"         { value = module.core.sns_topic_arn }
output "app_log_group_name"    { value = module.core.app_log_group_name }

# ── Bonus-A ─────────────────────────────────────────────────────
output "monitoring_endpoint_id" { value = module.section_a.monitoring_endpoint_id }

# ── Bonus-B ─────────────────────────────────────────────────────
output "alb_dns_name"          { value = module.section_b.alb_dns_name }

# ── Bonus-C ─────────────────────────────────────────────────────
output "app_url"               { value = module.section_c.app_url_https }
output "route53_zone_id"       { value = module.section_c.zone_id }
output "route53_nameservers"   { value = module.section_c.nameservers }

# ── Bonus-D ─────────────────────────────────────────────────────
output "apex_url"              { value = module.section_d.apex_url_https }
output "alb_logs_bucket"       { value = module.section_d.alb_logs_bucket_name }

# ── Bonus-E ─────────────────────────────────────────────────────
output "waf_log_group_name"    { value = module.section_e.waf_log_group_name }

# ── Bonus-G ─────────────────────────────────────────────────────
output "ir_reports_bucket"     { value = module.section_g.ir_reports_bucket }
