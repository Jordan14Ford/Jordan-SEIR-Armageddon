terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─────────────────────────────────────────────
# CORE  — VPC · EC2 · RDS · SSM · Secrets · SNS · CW alarm
# ─────────────────────────────────────────────
module "core" {
  source = "./core"

  aws_region           = var.aws_region
  project              = var.project
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat           = var.enable_nat
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_instance_class    = var.db_instance_class
  alert_email          = var.alert_email

}

# ─────────────────────────────────────────────
# BONUS-A  — VPC endpoints (SSM · CW · Secrets · S3)
# ─────────────────────────────────────────────
module "section_a" {
  source = "./section-a"

  aws_region           = var.aws_region
  project              = var.project
  vpc_id               = module.core.vpc_id
  private_subnet_ids   = module.core.private_subnet_ids
  private_subnet_cidrs = var.private_subnet_cidrs
  private_rt_id        = module.core.private_rt_id
}

# ─────────────────────────────────────────────
# BONUS-D  — S3 bucket for ALB access logs (must exist before section-b creates the ALB)
# ─────────────────────────────────────────────
module "section_d" {
  source = "./section-d"

  project      = var.project
  account_id   = module.core.account_id
  zone_id      = module.section_c.zone_id
  domain_name  = var.domain_name
  alb_dns_name = module.section_b.alb_dns_name
  alb_zone_id  = module.section_b.alb_zone_id
}

# ─────────────────────────────────────────────
# BONUS-B  — ALB · WAF · TG · HTTP redirect · 5xx alarm · dashboard
# depends on section-d for the log bucket name
# ─────────────────────────────────────────────
module "section_b" {
  source = "./section-b"

  aws_region           = var.aws_region
  project              = var.project
  vpc_id               = module.core.vpc_id
  public_subnet_ids    = module.core.public_subnet_ids
  ec2_instance_id      = module.core.ec2_instance_id
  ec2_sg_id            = module.core.ec2_sg_id
  sns_topic_arn        = module.core.sns_topic_arn
  alb_logs_bucket_name = module.section_d.alb_logs_bucket_name
}

# ─────────────────────────────────────────────
# BONUS-C  — Route53 hosted zone · ACM cert · DNS validation · HTTPS listener
# ─────────────────────────────────────────────
module "section_c" {
  source = "./section-c"

  project      = var.project
  domain_name  = var.domain_name
  app_subdomain = var.app_subdomain
  alb_arn      = module.section_b.alb_arn
  alb_dns_name = module.section_b.alb_dns_name
  alb_zone_id  = module.section_b.alb_zone_id
  tg_arn       = module.section_b.tg_arn
}

# ─────────────────────────────────────────────
# BONUS-E  — WAF logging → CloudWatch Logs
# ─────────────────────────────────────────────
module "section_e" {
  source = "./section-e"

  project = var.project
  waf_arn = module.section_b.waf_arn
}

# ─────────────────────────────────────────────
# BONUS-G  — Bedrock Auto-IR Lambda
# ─────────────────────────────────────────────
module "section_g" {
  source = "./section-g"

  aws_region         = var.aws_region
  project            = var.project
  account_id         = module.core.account_id
  sns_topic_arn      = module.core.sns_topic_arn
  app_log_group_name = module.core.app_log_group_name
  app_log_group_arn  = module.core.app_log_group_arn
  waf_log_group_name = module.section_e.waf_log_group_name
  waf_log_group_arn  = module.section_e.waf_log_group_arn
  db_secret_arn      = module.core.db_secret_arn
  db_secret_name     = module.core.db_secret_name
  bedrock_model_id   = var.bedrock_model_id
}
