output "vcs_workspace_name" {
  value = tfe_workspace.vcs_ws.name
}

output "vcs_workspace_repo" {
  value = join(", ", tfe_workspace.vcs_ws.vcs_repo[*].identifier)
}

output "vcs_workspace_branch" {
  value = join(", ", tfe_workspace.vcs_ws.vcs_repo[*].branch)
}

output "cli_workspaces_list" {
  value = [for ws in tfe_workspace.cli_ws : ws.name]
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