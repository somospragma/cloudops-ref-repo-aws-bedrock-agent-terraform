############################################
#             Agent Resources              #
# Module development supported by Amazon Q #
############################################

# Local values are defined in locals.tf
resource "aws_bedrockagent_agent" "agents" {
  provider = aws.project
  for_each = var.agents

  agent_name                  = local.agent_names[each.key]
  agent_resource_role_arn     = each.value.agent_resource_role_arn
  idle_session_ttl_in_seconds = each.value.idle_session_ttl_in_seconds
  foundation_model            = each.value.foundation_model
  instruction                 = file(each.value.instruction)
  customer_encryption_key_arn = each.value.customer_encryption_key_arn
  prepare_agent               = each.value.prepare_agent
  description                 = each.value.description

  # Configuración condicional de prompt override
  dynamic "prompt_override_configuration" {
    for_each = each.value.prompt_override_configuration != null ? [1] : []
    content {
      dynamic "prompt_configurations" {
        for_each = each.value.prompt_override_configuration
        content {
          base_prompt_template = file(prompt_configurations.value.template)
          parser_mode          = prompt_configurations.value.parser_mode
          prompt_creation_mode = prompt_configurations.value.prompt_creation_mode
          prompt_state         = prompt_configurations.value.prompt_state
          prompt_type          = prompt_configurations.value.prompt_type

          inference_configuration {
            max_length     = prompt_configurations.value.max_length
            stop_sequences = prompt_configurations.value.stop_sequences
            temperature    = prompt_configurations.value.temperature
            top_k          = prompt_configurations.value.top_k
            top_p          = prompt_configurations.value.top_p
          }
        }
      }
    }
  }

  # Configuración condicional de guardrail
  dynamic "guardrail_configuration" {
    for_each = each.value.guardrail_configuration != null ? each.value.guardrail_configuration : []
    content {
      guardrail_identifier = guardrail_configuration.value.guardrail_identifier
      guardrail_version    = guardrail_configuration.value.guardrail_version
    }
  }

  tags = merge(var.common_tags, each.value.additional_tags)
}

resource "aws_bedrockagent_agent_action_group" "user_input" {
  provider   = aws.project
  depends_on = [aws_bedrockagent_agent.agents]

  for_each = {
    for name, config in var.agents : name => config
    if config.is_user_input == true
  }

  action_group_name             = "UserInputAction"
  agent_id                      = aws_bedrockagent_agent.agents[each.key].agent_id
  agent_version                 = "DRAFT"
  skip_resource_in_use_check    = true
  parent_action_group_signature = "AMAZON.UserInput"
}

resource "aws_bedrockagent_agent_action_group" "action_groups" {
  provider   = aws.project
  depends_on = [aws_bedrockagent_agent_action_group.user_input]
  for_each = tomap({
    for action_group in local.action_groups : "${action_group.action_group_name}" => action_group
  })

  action_group_name          = each.value.action_group_name
  agent_id                   = each.value.agent_id
  agent_version              = "DRAFT"
  skip_resource_in_use_check = each.value.skip_resource_in_use_check
  action_group_executor {
    lambda = each.value.lambda_arn
  }
  api_schema {
    payload = file(each.value.api_schema)
  }
}

resource "aws_bedrockagent_agent_knowledge_base_association" "knowledge_base_associations" {
  provider   = aws.project
  depends_on = [aws_bedrockagent_agent.agents, aws_bedrockagent_agent_action_group.action_groups]
  
  #Solution: for_each error with static keys using flatten
  for_each = {
    for item in flatten([
      for agent_key, agent in var.agents : [
        for kb_idx, kb in (agent.knowledge_bases != null ? agent.knowledge_bases : []) : {
          key       = "${agent_key}-kb-${kb_idx}"
          agent_key = agent_key
          kb_config = kb
        }
      ]
    ]) : item.key => item
  }

  agent_id             = aws_bedrockagent_agent.agents[each.value.agent_key].agent_id
  description          = each.value.kb_config.description
  knowledge_base_id    = each.value.kb_config.knowledge_base_id
  knowledge_base_state = each.value.kb_config.knowledge_base_state
}

resource "null_resource" "prepare" {
  depends_on = [aws_bedrockagent_agent_action_group.action_groups]

  for_each = {
    for name, config in var.agents : name => config
    if config.prepare_agent == true
  }

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<EOF
      #aws_role=${var.aws_role_arn}

      if [ -z "${var.aws_role_arn}" ]; then
          #Be sure to set AWS_PROFILE and AWS_DEFAULT_REGION variables
          #export AWS_PROFILE=dev
          #export AWS_DEFAULT_REGION=us-east-1

          echo "aws_role is empty, using profile AWS_PROFILE"
          aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.agents[each.key].agent_id}
      else
          echo "aws_role is set to '$aws_role'"
          set -e
          CREDENTIALS=(`aws sts assume-role \
          --role-arn ${var.aws_role_arn} \
          --role-session-name "bedrock-cli" \
          --query "[Credentials.AccessKeyId,Credentials.SecretAccessKey,Credentials.SessionToken]" \
          --output text`)

          unset AWS_PROFILE
          export AWS_DEFAULT_REGION=${var.aws_region}
          export AWS_ACCESS_KEY_ID="$${CREDENTIALS[0]}"
          export AWS_SECRET_ACCESS_KEY="$${CREDENTIALS[1]}"
          export AWS_SESSION_TOKEN="$${CREDENTIALS[2]}"

          aws bedrock-agent prepare-agent --agent-id ${aws_bedrockagent_agent.agents[each.key].agent_id}
      fi
    EOF
  }
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [null_resource.prepare]

  create_duration = "60s"

  triggers = {
    always_run = timestamp()
  }
}

resource "time_static" "time" {
  triggers = {
    always_run = timestamp()
  }
}

resource "aws_bedrockagent_agent_alias" "agent_alias" {
  provider   = aws.project
  depends_on = [time_sleep.wait_30_seconds]

  for_each = var.agents

  agent_alias_name = "${local.agent_names[each.key]}-${time_static.time.unix}-alias"
  agent_id         = aws_bedrockagent_agent.agents[each.key].agent_id
  description      = "${local.agent_names[each.key]} alias"

  lifecycle {
    replace_triggered_by = [
      time_sleep.wait_30_seconds
    ]
  }
}
