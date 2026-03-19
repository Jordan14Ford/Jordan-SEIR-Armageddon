# osaka variables - failover region for tokyo

variable "aws_profile" {
  type    = string
  default = "default"
}

variable "aws_region" {
  type    = string
  default = "ap-northeast-3"  # osaka
}

variable "project" {
  type    = string
  default = "lab3"
}

variable "environment" {
  type    = string
  default = "student"
}

# networking
# tokyo = 10.0.x.x, sao paulo = 10.1.x.x, osaka = 10.2.x.x
variable "osaka_vpc_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "osaka_public_subnet_1_cidr" {
  type    = string
  default = "10.2.1.0/24"
}

variable "osaka_public_subnet_2_cidr" {
  type    = string
  default = "10.2.2.0/24"
}

variable "osaka_private_subnet_1_cidr" {
  type    = string
  default = "10.2.10.0/24"
}

variable "osaka_private_subnet_2_cidr" {
  type    = string
  default = "10.2.11.0/24"
}

# tokyo cidr - for TGW routing
variable "tokyo_vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

# ec2
variable "instance_type" {
  type    = string
  default = "t3.micro"
}

# osaka AMI - amazon linux 2023
variable "ami_id" {
  type    = string
  default = "ami-0f8609c9f7ce63f42"  # AL2023 osaka
}

# tokyo TGW ID - fill in after tokyo is deployed
variable "tokyo_tgw_id" {
  type    = string
  default = ""
}

# tokyo RDS endpoint - app connects here
variable "tokyo_rds_endpoint" {
  type    = string
  default = ""
}
