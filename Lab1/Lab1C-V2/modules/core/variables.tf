variable "aws_region"          { type = string }
variable "project"             { type = string }
variable "vpc_cidr"            { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "enable_nat"          { type = bool }
variable "db_name"             { type = string }
variable "db_username"         { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class"   { type = string }
variable "alert_email"         { type = string }

