# Configure TFE provider
terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.65.0"
    }
  }
}

# Convert workspace names input to set
locals {
  vcs_workspaces = toset(var.vcs_workspaces_name_list)
}

# Create a project and assign the workspaces to the same project
resource "tfe_project" "galaxy" {
  organization = var.organization_name
  name         = "project-${var.project_name}"
}

# Commented as we're not using VCS OAuth Connection
# We use a simple Github App approach instead
/* data "tfe_oauth_client" "client" {
  oauth_client_id = var.oauth_client_id
}
 */

# Create a workspace with CLI-driven workflow
resource "tfe_workspace" "cli_ws" {

  name           = "cli-${var.cli_workspace_name}"
  organization   = var.organization_name
  project_id     = tfe_project.galaxy.id
  queue_all_runs = false
  auto_apply     = true
}

# Create 3 workspaces with VCS-driven workflow
resource "tfe_workspace" "vcs_ws" {
  for_each = local.vcs_workspaces

  name           = "vcs-${each.key}"
  organization   = var.organization_name
  project_id     = tfe_project.galaxy.id
  queue_all_runs = false
  auto_apply     = true

  vcs_repo {
    identifier = "${var.github_user}/${var.github_repo}"
    #oauth_token_id = data.tfe_oauth_client.client.oauth_token_id
    github_app_installation_id = var.github_app_installation_id
    branch                     = local.vcs_repo_branch
  }
}


# Create a variable set containing: a terraform variable and an environment variable
resource "tfe_variable_set" "default_varset" {
  name         = "Cloud credentials"
  description  = "Default varset for workspace. Here we use AWS cloud creds as example"
  organization = var.organization_name
}


# A terraform variable
resource "tfe_variable" "aws_region" {
  key             = "AWS_REGION"
  value           = var.default_aws_region
  category        = "terraform"
  variable_set_id = tfe_variable_set.default_varset.id
}

# An environment variable
resource "tfe_variable" "aws_access_key_id" {
  key             = "AWS_ACCESS_KEY_ID"
  value           = var.aws_access_key_id
  category        = "env"
  description     = "AWS credential key id"
  variable_set_id = tfe_variable_set.default_varset.id
}

# Another environment variable
resource "tfe_variable" "aws_secret_access_key" {
  key             = "AWS_SECRET_ACCESS_KEY"
  sensitive       = true
  value           = var.aws_secret_access_key
  category        = "env"
  description     = "AWS credential key secret"
  variable_set_id = tfe_variable_set.default_varset.id
}


resource "tfe_variable_set" "cli_varset" {
  name         = "CLI workspace variables (test)"
  description  = "Special varset for CLI workspace."
  organization = var.organization_name
}


# Telegram bot token for the CLI workspace
resource "tfe_variable" "telegram_bot_token" {
  key             = "TF_VAR_TELEGRAM_BOT_TOKEN"
  sensitive       = true
  value           = var.TELEGRAM_BOT_TOKEN_DEV
  category        = "env"
  description     = "Telegram bot token"
  variable_set_id = tfe_variable_set.cli_varset.id
}


# API client ID for OpenWeatherMap API
resource "tfe_variable" "openweathermap_client_id" {
  key             = "TF_VAR_OPENWEATHERMAP_ORG_APP_ID"
  sensitive       = true
  value           = var.OPENWEATHERMAP_ORG_APP_ID
  category        = "env"
  description     = "OpenWeatherMap API ID"
  variable_set_id = tfe_variable_set.cli_varset.id
}


# TODO: Create execution role dynamically.
# static resource for Lambda execution role ARN
resource "tfe_variable" "lambda_role_arn" {
  key             = "lambda_role_arn"
  value           = var.lambda_role_arn
  category        = "terraform"
  description     = "ARN of the Lambda execution role"
  variable_set_id = tfe_variable_set.cli_varset.id
}

/*
# TODO: Create layer dynamically.
# static resource for Lambda layer ARN
resource "tfe_variable" "lambda_layer_arn" {
  key             = "lambda_layer_arn"
  value           = var.lambda_layer_arn
  category        = "terraform"
  description     = "ARN of the Lambda layer"
  variable_set_id = tfe_variable_set.cli_varset.id
}
*/

# Uncomment to apply the variable set to the CLI workspace
resource "tfe_workspace_variable_set" "cli_ws_varset" {
  workspace_id    = tfe_workspace.cli_ws.id
  variable_set_id = tfe_variable_set.cli_varset.id
}


# Make sure the variable set has been applied to all VCS workspaces
resource "tfe_workspace_variable_set" "vcs_ws_varset" {
  for_each = tfe_workspace.vcs_ws

  workspace_id    = each.value.id
  variable_set_id = tfe_variable_set.default_varset.id
}

# Initiate the first run of the workspace
resource "tfe_workspace_run" "initial_vcs_run" {
  for_each = tfe_workspace.vcs_ws

  workspace_id = each.value.id

  apply {
    manual_confirm = false
    wait_for_run   = false
  }
  # depends_on = tfe_workspace_variable_set.vcs_ws_varset
}


/* # Initialize and apply the HCP Terraform Simple Landing Zone module
module "tfc-simple-lz" {
  source = "./modules/tfc-simple-lz"

  app_name              = var.app_name
  aws_vpc_id            = module.aws-simple-lz.vpc_id
  aws_public_subnet_id  = module.aws-simple-lz.public_subnet_id
  aws_private_subnet_id = module.aws-simple-lz.private_subnet_id
  aws_s3_bucket_arn     = module.aws-simple-lz.s3_bucket_arn
  aws_access_key_id     = module.aws-simple-lz.aws_access_key_id
  aws_secret_access_key = module.aws-simple-lz.aws_secret_access_key
  gitlab_group_path     = var.gitlab_group_path
  oauth_client_id       = var.oauth_client_id
} */