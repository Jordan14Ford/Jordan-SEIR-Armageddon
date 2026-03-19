# =============================================================================
# LAB 3 - SAO PAULO VARIABLES
# File: lab3/sao-paulo/variables.tf
# Region: sa-east-1 (Sao Paulo)
# Purpose: Single source of truth for all configurable values in the Sao Paulo
#          state root. Mirrors Tokyo structure but WITHOUT any database variables.
#
# KEY DIFFERENCE FROM TOKYO:
#   - No db_name, db_username, db_password, db_instance_class variables
#   - Sao Paulo is COMPUTE ONLY - no data at rest
#   - The Flask app here connects to Tokyo RDS over the TGW corridor
#
# CIDR DECISIONS (must match Tokyo):
#   Tokyo VPC:     10.0.0.0/16
#   Sao Paulo VPC: 10.1.0.0/16
#   Non-overlapping CIDRs required for TGW routing to work.
# =============================================================================


# -----------------------------------------------------------------------------
# TOKYO REMOTE STATE
# Reads outputs from the Tokyo state file. This is how Sao Paulo knows the
# Tokyo TGW ID, RDS endpoint, and VPC CIDR without hardcoding them.
# -----------------------------------------------------------------------------

data "terraform_remote_state" "tokyo" {
  backend = "local"

  config = {
    path = "../tokyo/terraform.tfstate"
  }
}


# -----------------------------------------------------------------------------
# AUTHENTICATION
# -----------------------------------------------------------------------------

variable "aws_profile" {
  description = "AWS CLI named profile to use for authentication. Must have permissions in sa-east-1."
  type        = string
  default     = "default"
}


# -----------------------------------------------------------------------------
# REGION + NAMING
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for Sao Paulo. Hardcoded to sa-east-1."
  type        = string
  default     = "sa-east-1"
}

variable "project" {
  description = "Short project name used as a prefix in all resource names."
  type        = string
  default     = "lab3"
}

variable "environment" {
  description = "Environment label. Used in tags and resource names."
  type        = string
  default     = "student"
}


# -----------------------------------------------------------------------------
# NETWORKING - SAO PAULO VPC
# Subnets carved out of the Sao Paulo VPC CIDR (10.1.0.0/16).
# Public subnets host the ALB. Private subnets host EC2 only (no RDS here).
# Two AZs for redundancy - sa-east-1a and sa-east-1b.
# -----------------------------------------------------------------------------

variable "sao_paulo_vpc_cidr" {
  description = "CIDR block for the Sao Paulo VPC. Must not overlap with Tokyo (10.0.0.0/16)."
  type        = string
  default     = "10.1.0.0/16"
}

variable "sao_paulo_public_subnet_1_cidr" {
  description = "Public subnet in AZ sa-east-1a. Hosts the ALB."
  type        = string
  default     = "10.1.1.0/24"
}

variable "sao_paulo_public_subnet_2_cidr" {
  description = "Public subnet in AZ sa-east-1b. Second AZ for ALB requirement."
  type        = string
  default     = "10.1.2.0/24"
}

variable "sao_paulo_private_subnet_1_cidr" {
  description = "Private subnet in AZ sa-east-1a. Hosts EC2 app instances."
  type        = string
  default     = "10.1.10.0/24"
}

variable "sao_paulo_private_subnet_2_cidr" {
  description = "Private subnet in AZ sa-east-1b. Second AZ for redundancy."
  type        = string
  default     = "10.1.11.0/24"
}


# -----------------------------------------------------------------------------
# NETWORKING - TOKYO REFERENCE
# Tokyo CIDR is referenced for route table entries. Traffic destined for
# 10.0.0.0/16 gets routed through the TGW to reach Tokyo RDS.
# -----------------------------------------------------------------------------

variable "tokyo_vpc_cidr" {
  description = "CIDR block for the Tokyo VPC. Used in route tables to send Tokyo-bound traffic through the TGW."
  type        = string
  default     = "10.0.0.0/16"
}


# -----------------------------------------------------------------------------
# COMPUTE - EC2
# -----------------------------------------------------------------------------

variable "instance_type" {
  description = "EC2 instance type for the Sao Paulo app tier. t3.micro keeps costs low."
  type        = string
  default     = "t3.micro"
}

variable "ami_id" {
  description = "Amazon Machine Image ID for EC2 instances. Amazon Linux 2023 in sa-east-1."
  type        = string
  default     = "ami-0b636fa791bb0970c" # Amazon Linux 2023 - sa-east-1 (verified 2026-03-13)
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access (fallback only - SSM is preferred)."
  type        = string
  default     = ""
}


# -----------------------------------------------------------------------------
# TGW CONFIGURATION
# -----------------------------------------------------------------------------

variable "sao_paulo_tgw_asn" {
  description = "BGP ASN for the Sao Paulo Transit Gateway. Must be different from Tokyo TGW ASN."
  type        = number
  default     = 64513
}
