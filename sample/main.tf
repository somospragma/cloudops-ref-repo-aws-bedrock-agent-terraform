# Bedrock Agent Module - Sample Configuration

# Lambda Layers Module
module "sample_agent" {
  source = "../"
  providers = {
    aws.project = aws.principal
  }
  environment = var.environment
  project     = var.project
  client      = var.client
  common_tags = var.common_tags
  agents      = var.agents
}
