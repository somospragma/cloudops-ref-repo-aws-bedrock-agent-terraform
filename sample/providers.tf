# Lambda Layers Sample - Provider Configuration
##############################################################
# Config Providers Terraform - AWS
##############################################################
provider "aws" {
  region = var.aws_region
  alias  = "principal"
  profile = var.profile
  # assume_role {
  #   role_arn = var.deploy_role_arn
  # }

  default_tags {
    tags = var.common_tags
  }
}

##############################################################
# Config Baceknd Terraform
##############################################################
terraform {
  required_version = ">= 1.10.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }
  # backend "s3" {
  # }
}
