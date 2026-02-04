data "aws_caller_identity" "current" {
  provider = aws.project
}

data "aws_partition" "current" {
  provider = aws.project
}

data "aws_region" "current" {
  provider = aws.project
}
