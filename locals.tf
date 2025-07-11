###########################################
############ Local Values #################
###########################################

locals {
  /* # Merge all Lambda functions from both resources (only if they exist)
  all_lambda_functions = merge(
    try(aws_lambda_function.directory_functions, {}),
    try(aws_lambda_function.s3_functions, {})
  )

  # Flatten permissions from all functions with unique keys
  all_permissions = merge([
    for func_key, func in var.lambda_functions : {
      for idx, permission in func.permissions : 
      "${func_key}-${idx}" => merge(permission, {
        function_key = func_key
      })
    }
  ]...)
*/
  # Generate standard names for functions following convention: {client}-{project}-{environment}-lambda-{map_key}
  agent_names = {
    for k, v in var.agents : k => "${var.client}-${var.project}-${var.environment}-agent-${k}"
  }
  /*
  # Generate standard names for log groups using map key: /aws/lambda/{map_key}
  log_group_names = {
    for k, v in var.lambda_functions : k => "/aws/lambda/${k}"
  }*/


  # flatten ensures that this local value is a flat list of objects, rather
  # than a list of lists of objects.
  action_groups = flatten([
    for agent_key, agent in var.agents : [
      for action_group_key, action_group in tomap({
        for action_group in agent.action_groups : action_group.action_group_name => action_group
        }) : {
        action_group_name          = action_group.action_group_name
        agent_id                   = aws_bedrockagent_agent.agents[agent_key].agent_id
        skip_resource_in_use_check = action_group.skip_resource_in_use_check
        lambda_arn                 = action_group.lambda_arn
        api_schema                 = action_group.api_schema
      }
    ]
  ])

  knowledge_bases = flatten([
    for agent_key, agent in var.agents : [
      for knowledge_base_key, knowledge_base in tomap({
        for knowledge_base in agent.knowledge_bases : knowledge_base.knowledge_base_id => knowledge_base
        }) : {
        description          = knowledge_base.description
        agent_id             = aws_bedrockagent_agent.agents[agent_key].agent_id
        knowledge_base_id    = knowledge_base.knowledge_base_id
        knowledge_base_state = knowledge_base.knowledge_base_state
      }
    ]
  ])

}
