# Lambda Layers Sample - Data Sources

# Current AWS region
data "aws_region" "current" {
  provider = aws.principal
}

# Current AWS caller identity
data "aws_caller_identity" "current" {
  provider = aws.principal
}

data "aws_partition" "current" {
  provider = aws.principal
}

