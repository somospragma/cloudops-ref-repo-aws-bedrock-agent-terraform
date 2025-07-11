variable "common_tags" {
  type        = map(string)
  description = "Common tags to be applied to the resources"
}

variable "agents" {
  description = "Map of agents to create"
  type = map(object({
    # Agent Configuration
    description                 = optional(string, "Bedrock Agent")
    instruction                 = string
    foundation_model            = string
    prepare_agent               = bool
    customer_encryption_key_arn = optional(string)
    prompt_override_configuration = optional(list(object({
      template             = string
      prompt_type          = string
      prompt_state         = string
      prompt_creation_mode = string
      parser_mode          = string
      max_length           = number
      stop_sequences       = list(string)
      temperature          = number
      top_k                = number
      top_p                = number
    })))
    action_groups = optional(list(object({
      action_group_name          = string
      skip_resource_in_use_check = bool
      lambda_arn                 = string
      api_schema                 = string
    })))
    knowledge_bases = optional(list(object({
      description          = string
      knowledge_base_id    = string
      knowledge_base_state = string
    })))
    guardrail_configuration = optional(list(object({
      guardrail_identifier = string
      guardrail_version    = string
    })))
    agent_resource_role_arn     = string
    idle_session_ttl_in_seconds = number
    is_user_input               = bool
    # Agent tags
    additional_tags = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.agents : length(v.instruction) >= 10 && length(v.instruction) <= 128
    ])
    error_message = "Agent type must be have instruction"
  }

}

###########################################
#       Sistema de Etiquetado             #
###########################################

variable "client" {
  description = "Client name for resource naming and tagging"
  type        = string
}

variable "project" {
  description = "Project name for resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Environment name for resource naming and tagging"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "pdn"], var.environment)
    error_message = "El entorno debe ser uno de: dev, qa, pdn."
  }
}

variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  type        = string
  default     = ""
}

variable "profile" {
  description = "Profile AWS"
}

variable "aws_role_arn" {
  description = "AWS role ARN for cli execution"
  type        = string
}