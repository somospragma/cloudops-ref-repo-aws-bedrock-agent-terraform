###########################################
############ Local Values #################
###########################################

locals {
  
  # Generate standard names for functions following convention: {client}-{project}-{environment}-lambda-{map_key}
  agent_names = {
    for k, v in var.agents : k => "${var.client}-${var.project}-${var.environment}-agent-${k}"
  }

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
}
