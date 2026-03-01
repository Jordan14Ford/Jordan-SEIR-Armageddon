terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS provider - using variable for region so I can change it easily
# took me a bit to figure out the version constraint syntax
provider "aws" {
  region = var.aws_region
}