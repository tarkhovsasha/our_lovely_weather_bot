/*
locals {
  vcs_repo_branch = lookup({
    "production-ws"  = var.vcs_production_repo_branch
    "development-ws" = var.vcs_development_repo_branch
    "staging-ws"     = var.vcs_staging_repo_branch
  }, var.cli_workspace_name, var.vcs_development_repo_branch)
}
*/

# Map for lookup git branch for each VCS workspace
locals {
  vcs_repo_branch = {
    "production-ws"  = var.vcs_production_repo_branch
    "development-ws" = var.vcs_development_repo_branch
    "staging-ws"     = var.vcs_staging_repo_branch
  }
}

# Map environment suffixes to the corresponding Telegram token input.
locals {
  telegram_bot_tokens_by_environment = {
    DEV   = var.TELEGRAM_BOT_TOKEN_DEV
    STAGE = var.TELEGRAM_BOT_TOKEN_STAGE
    PROD  = var.TELEGRAM_BOT_TOKEN_PROD
  }

  telegram_bot_tokens = {
    for workspace, environment in var.vcs_workspaces_env_map : workspace =>
    local.telegram_bot_tokens_by_environment[environment]
  }
}

# Convert workspace names input to set
locals {
  vcs_workspaces = toset(var.vcs_workspaces_name_list)
}
