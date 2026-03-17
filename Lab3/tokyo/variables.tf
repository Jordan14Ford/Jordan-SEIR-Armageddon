# tokyo variables

variable "aws_profile" {
  description = "AWS CLI profile"
  type        = string
  default     = "default"
}

variable "aws_region" {
  description = "Tokyo region"
  type        = string
  default     = "ap-northeast-1"
}

variable "project" {
  description = "Project prefix for naming"
  type        = string
  default     = "lab3"
}

variable "environment" {
  type    = string
  default = "student"
}


# networking - don't change these CIDRs after deployment
# tokyo = 10.0.x.x, sao paulo = 10.1.x.x

variable "tokyo_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "tokyo_public_subnet_1_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "tokyo_public_subnet_2_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "tokyo_private_subnet_1_cidr" {
  type    = string
  default = "10.0.10.0/24"
}

variable "tokyo_private_subnet_2_cidr" {
  type    = string
  default = "10.0.11.0/24"
}

# sao paulo cidr - needed for security group rules
variable "sao_paulo_vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}


# ec2

variable "instance_type" {
  type    = string
  default = "t3.micro"  # cheapest
}

variable "ami_id" {
  type    = string
  default = "ami-0599b6e53ca798bb2"  # amazon linux 2023 tokyo - check this is still valid
}

variable "key_pair_name" {
  type    = string
  default = ""  # using SSM instead
}

# rds - only database in the whole lab, sao paulo connects here via TGW

variable "db_name" {
  type    = string
  default = "lab3db"
}

variable "db_username" {
  type    = string
  default = "admin"
}

variable "db_password" {
  type      = string
  sensitive = true
  default   = ""  # set in tfvars
}

variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}

# fill this in after sao paulo is deployed
variable "sao_paulo_tgw_id" {
  type    = string
  default = ""
}

# osaka - failover region
variable "osaka_vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "osaka_tgw_id" {
  type    = string
  default = ""
}

variable "osaka_peering_attachment_id" {
  type    = string
  default = ""
}
