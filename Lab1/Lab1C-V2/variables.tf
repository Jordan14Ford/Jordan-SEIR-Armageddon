# ============================================================
# variables.tf — Lab 1C input variables
# All resources use var.project as a naming prefix
# ============================================================

variable "aws_region" {
  description = "AWS region to deploy into. All resources land here."
  type        = string
  default     = "us-east-1"
  # change this if deploying to a different region
  # note: some AMI IDs are region-specific so you may need to update ec2.tf too
}

variable "project" {
  # This prefix gets stamped on every resource name
  # example: cloudyjones-alb01, cloudyjones-vpc01, etc.
  description = "Project name — used as prefix for all resource names"
  type        = string
  default     = "cloudyjones"
}

variable "vpc_cidr" {
  # /16 gives us 65,536 IPs to carve subnets from
  # we only use a small slice of this for the lab
  description = "CIDR block for the custom VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ALB requires at least 2 subnets in different AZs
# these subnets have a route to the internet gateway
variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  # 10.0.1.0/24 = us-east-1a
  # 10.0.2.0/24 = us-east-1b
}

# EC2 lives here — no public IP, no direct internet route
# traffic in: only from ALB security group
# traffic out: only through VPC endpoints (no NAT gateway = no cost)
variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
  # using .11 and .12 to make it visually obvious these are private
  # vs .1 and .2 for public above
}

# CloudWatch alarm fires → SNS topic → this email
# you need to confirm the subscription in your inbox after first apply
variable "alert_email" {
  description = "Email address for SNS alarm notifications"
  type        = string
  default     = "jordanxavi95@gmail.com"
}

# domain purchased on Namecheap, nameservers delegated to Route53
# ACM cert covers both cloudyjones.xyz and app.cloudyjones.xyz
variable "domain_name" {
  description = "Root domain for Route53 hosted zone and ACM cert"
  type        = string
  default     = "cloudyjones.xyz"
}

# final URL ends up as app.cloudyjones.xyz → ALB → private EC2
variable "app_subdomain" {
  description = "Subdomain prefix for the Flask app"
  type        = string
  default     = "app"
}

variable "enable_nat" {
  description = "Enable NAT gateway for pip install. Set false for strict Bonus-A no-internet posture."
  type        = bool
  default     = true
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "labdb"
}

variable "db_username" {
  description = "RDS master username used by the app secret."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS master password used by Terraform and Secrets Manager."
  type        = string
  sensitive   = true
  default     = "ChangeMeLab1c!123"
}

variable "db_instance_class" {
  description = "RDS instance size for the lab."
  type        = string
  default     = "db.t3.micro"
}

variable "bedrock_model_id" {
  description = "Bedrock model used by bonus G incident report lambda."
  type        = string
  default     = "amazon.titan-text-express-v1"
}