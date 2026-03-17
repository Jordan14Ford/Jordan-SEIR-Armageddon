# providers.tf
# tells terraform what plugins to download and how to talk to AWS

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# default provider — this is what most of my resources use
# region gets pulled from var.aws_region in variables.tf
provider "aws" {
  region = var.aws_region
}

# cloudfront is a global service but AWS requires certain things
# to exist specifically in us-east-1 no matter what region your
# stack is in — mainly:
#   - WAFv2 web ACL (has to be CLOUDFRONT scope, not regional)
#   - ACM cert that cloudfront uses for HTTPS on the viewer side
# when i reference these resources i have to add provider = aws.us_east_1
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
