# =============================================================================
# LAB 3 — TOKYO REGION PROVIDER CONFIGURATION
# File: lab3/tokyo/provider.tf
# Region: ap-northeast-1 (Tokyo) + us-east-1 alias for WAF/CloudFront
#
# APPI COMPLIANCE NOTE:
#   Japan's APPI requires PHI remain physically stored within Japan.
#   This provider pins all core resources to ap-northeast-1 (Tokyo).
#   Do NOT change this region without a compliance review.
#
# WHY TWO PROVIDERS:
#   AWS requires WAF WebACLs for CloudFront to be provisioned in us-east-1
#   regardless of where the application runs. CloudFront's global control
#   plane only accepts WAF ACLs from us-east-1 — this is a hard AWS
#   constraint, not a design choice. The alias "aws.useast1" is used only
#   for WAF and CloudFront. All other Tokyo resources stay in ap-northeast-1.
# =============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# -----------------------------------------------------------------------------
# PRIMARY PROVIDER — TOKYO (ap-northeast-1)
# All Tokyo infrastructure: VPC, EC2, RDS, TGW, SG, routes
# -----------------------------------------------------------------------------
provider "aws" {
  region  = "ap-northeast-1"
  profile = var.aws_profile

  default_tags {
    tags = {
      Lab         = "lab3-tokyo"
      Environment = "student"
      ManagedBy   = "terraform"
      Compliance  = "APPI"
      Region      = "ap-northeast-1"
    }
  }
}

# -----------------------------------------------------------------------------
# ALIAS PROVIDER — US-EAST-1
# Used exclusively for WAF WebACL and CloudFront distribution.
# AWS mandates WAF for CloudFront must be provisioned in us-east-1.
# Resources using this alias: aws_wafv2_web_acl, aws_cloudfront_distribution
# -----------------------------------------------------------------------------
provider "aws" {
  alias   = "useast1"
  region  = "us-east-1"
  profile = var.aws_profile

  default_tags {
    tags = {
      Lab         = "lab3-tokyo"
      Environment = "student"
      ManagedBy   = "terraform"
      Compliance  = "APPI"
      Note        = "WAF and CloudFront control plane only"
    }
  }
}
