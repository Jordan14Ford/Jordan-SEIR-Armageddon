variable "aws_region"          { type = string }
variable "project"             { type = string }
variable "vpc_id"              { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "private_subnet_cidrs" { type = list(string) }
variable "private_rt_id"       { type = string }
