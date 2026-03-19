variable "aws_region"           { type = string }
variable "project"              { type = string }
variable "vpc_id"               { type = string }
variable "public_subnet_ids"    { type = list(string) }
variable "ec2_instance_id"      { type = string }
variable "ec2_sg_id"            { type = string }
variable "sns_topic_arn"        { type = string }
variable "alb_logs_bucket_name" { type = string }
