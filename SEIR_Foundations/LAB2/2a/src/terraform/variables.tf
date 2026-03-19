# variables.tf
# all my input variables live here instead of being hardcoded
# inside the resource blocks — easier to update later

variable "project" {
  # prefix that gets slapped onto every resource name i create
  # so in the console everything shows up as cloudyjones-whatever
  description = "Project prefix used for all resource names"
  type        = string
  default     = "cloudyjones"
}

variable "aws_region" {
  # where everything gets deployed — ALB, EC2, all of it
  description = "Primary region where ALB and EC2 live"
  type        = string
  default     = "us-east-1"
}

variable "origin_secret" {
  # this is the secret that ties cloudfront and the ALB together
  # cloudfront adds it as a custom header (X-Chewbacca-Growl) on every request
  # the ALB checks for it — if its missing or wrong it returns 403
  # basically stops people from hitting the ALB directly and skipping cloudfront
  # sensitive = true so terraform doesnt print it in the terminal output
  description = "Secret value injected by CloudFront as X-Chewbacca-Growl header"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  # my root domain in route 53
  # used when creating DNS records that point at the cloudfront distribution
  description = "Root domain name"
  type        = string
  default     = "cloudyjones.xyz"
}
