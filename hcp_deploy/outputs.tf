output "cli_workspaces_list" {
  value = tfe_workspace.cli_ws.name
}

output "vcs_workspace_list" {
  value = [for ws in tfe_workspace.vcs_ws : ws.name]
}

output "vcs_workspace_repos" {
  value = {
    for key, ws in tfe_workspace.vcs_ws :
    key => ws.vcs_repo[0].identifier
  }
}

output "vcs_workspace_branches" {
  value = {
    for key, ws in tfe_workspace.vcs_ws :
    key => ws.vcs_repo[0].branch
  }
}

/*
output "aws_access_key_id" {
  value = "" #module.aws-simple-lz.aws_access_key_id
}

output "aws_secret_access_key" {
  value     = "" #module.aws-simple-lz.aws_secret_access_key
  sensitive = true
}
*/