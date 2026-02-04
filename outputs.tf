###########################################
################ Outputs ##################
###########################################

###########################################
############ Agent Functions #############
###########################################

output "agents" {
  description = "Complete information about all agents created"
  value = {
    for k, v in var.agents : k => {
      agent_arn       = aws_bedrockagent_agent.agents[k].agent_arn
      agent_id        = aws_bedrockagent_agent.agents[k].agent_id
      agent_alias_id  = aws_bedrockagent_agent_alias.agent_alias[k].agent_alias_id
      agent_alias_arn = aws_bedrockagent_agent_alias.agent_alias[k].agent_alias_arn
    }
  }
}
