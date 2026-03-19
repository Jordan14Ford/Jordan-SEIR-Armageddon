# =============================================================================
# LAB 3 - SAO PAULO PROVIDER CONFIGURATION
# File: lab3/sao-paulo/provider.tf
# Region: sa-east-1 (Sao Paulo)
# Purpose: Configures the AWS provider for the Sao Paulo state root.
#          This is a SEPARATE state from Tokyo - each region has its own
#          terraform.tfstate file.
#
# WHY SEPARATE STATE ROOTS?
#   1. Regional isolation - if one state corrupts, the other is unaffected
#   2. Independent apply cycles - can update Sao Paulo without touching Tokyo
#   3. Mirrors real-world multi-region patterns
#   4. TGW peering requires resources in both regions anyway
#
# APPLY ORDER:
#   Tokyo MUST be applied first. Sao Paulo reads Tokyo outputs via
#   terraform_remote_state, so Tokyo state must exist before Sao Paulo plan.
# =============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      Region      = "sao-paulo"
      ManagedBy   = "terraform"
    }
  }
}
