# route53 failover between tokyo and osaka
# deploy this after both tokyo and osaka are up

provider "aws" {
  region  = "us-east-1"  # Route 53 is global, use us-east-1
  profile = var.aws_profile
}

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "domain_name" {
  type        = string
  description = "Domain for the app (e.g., lab3.example.com)"
  default     = ""  # set in tfvars
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 hosted zone ID"
  default     = ""  # set in tfvars
}

variable "tokyo_alb_dns" {
  type    = string
  default = ""
}

variable "tokyo_alb_zone_id" {
  type    = string
  default = ""  # ALB hosted zone ID for alias record
}

variable "osaka_alb_dns" {
  type    = string
  default = ""
}

variable "osaka_alb_zone_id" {
  type    = string
  default = ""
}

# health check for tokyo ALB
resource "aws_route53_health_check" "tokyo_health" {
  count = var.tokyo_alb_dns != "" ? 1 : 0

  fqdn              = var.tokyo_alb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "lab3-tokyo-health-check"
  }
}

# health check for osaka ALB
resource "aws_route53_health_check" "osaka_health" {
  count = var.osaka_alb_dns != "" ? 1 : 0

  fqdn              = var.osaka_alb_dns
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "lab3-osaka-health-check"
  }
}

# primary record - tokyo
resource "aws_route53_record" "primary" {
  count = var.hosted_zone_id != "" && var.tokyo_alb_dns != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.tokyo_alb_dns
    zone_id                = var.tokyo_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "PRIMARY"
  }

  set_identifier  = "tokyo-primary"
  health_check_id = aws_route53_health_check.tokyo_health[0].id
}

# secondary record - osaka (failover)
resource "aws_route53_record" "secondary" {
  count = var.hosted_zone_id != "" && var.osaka_alb_dns != "" ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.osaka_alb_dns
    zone_id                = var.osaka_alb_zone_id
    evaluate_target_health = true
  }

  failover_routing_policy {
    type = "SECONDARY"
  }

  set_identifier  = "osaka-secondary"
  health_check_id = aws_route53_health_check.osaka_health[0].id
}

output "tokyo_health_check_id" {
  value = var.tokyo_alb_dns != "" ? aws_route53_health_check.tokyo_health[0].id : "not created"
}

output "osaka_health_check_id" {
  value = var.osaka_alb_dns != "" ? aws_route53_health_check.osaka_health[0].id : "not created"
}
