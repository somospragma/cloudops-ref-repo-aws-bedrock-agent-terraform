###########################################
#Version definition - Terraform - Providers
###########################################

terraform {
  required_providers {
    aws = {
      configuration_aliases = [aws.project]
      source                = "hashicorp/aws"
      version               = ">=4.31.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.0"
    }

  }
}
