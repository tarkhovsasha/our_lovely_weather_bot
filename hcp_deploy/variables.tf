variable "github_user" {
  type    = string
  default = "tarkhovsasha"
}

variable "github_repo" {
  type    = string
  default = "galaxy-far-away-repo"
}

variable "github_app_installation_id" {
  type      = string
  sensitive = true
}

variable "vcs_production_repo_branch" {
  type    = string
  default = "main"
}

variable "vcs_staging_repo_branch" {
  type    = string
  default = "stage"
}

variable "vcs_development_repo_branch" {
  type    = string
  default = "development"
}


variable "organization_name" {
  type        = string
  default     = "technical-assessment-org"
  description = "Name of the existing HCP Cloud organization."
}

variable "project_name" {
  type        = string
  default     = "galaxy-far-away"
  description = "Suffix for the name of the project."

  validation {
    condition     = length(var.project_name) > 4
    error_message = "The project name value must be longer than 4 characters."
  }
}

variable "cli_workspace_name" {
  type        = string
  default     = "sandbox-ws"
  description = "Name of the CLI workspace."

  validation {
    condition     = length(var.cli_workspace_name) > 4
    error_message = "The workspace name value must be longer than 4 characters."
  }
}

variable "vcs_workspaces_name_list" {
  type        = list(string)
  default     = ["development-ws", "staging-ws", "production-ws"]
  description = "List of VCS workspace names."

  validation {
    condition = alltrue([
      for str in var.vcs_workspaces_name_list : str != ""
      ]) && length(var.vcs_workspaces_name_list) == length(distinct([
        for str in var.vcs_workspaces_name_list : lower(str)
    ]))
    error_message = "All names must be non-empty and unique."
  }
}

variable "vcs_workspaces_env_map" {
  type = map(string)
  default = {
    "development-ws" = "DEV"
    "staging-ws"     = "STAGE"
    "production-ws"  = "PROD"
  }
  description = "Map of VCS workspace names to their environment."

  validation {
    condition = alltrue([
      for environment in values(var.vcs_workspaces_env_map) : contains(["DEV", "STAGE", "PROD"], environment)
      ]) && length(var.vcs_workspaces_env_map) == length(distinct([
        for environment in values(var.vcs_workspaces_env_map) : lower(environment)
    ]))
    error_message = "Environment suffixes must be unique and one of DEV, STAGE, or PROD."
  }
}


variable "default_aws_region" {
  type        = string
  default     = "us-west-2"
  description = "Configure default aws region to be used"
}

variable "aws_access_key_id" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_KEY_ID"
  description = "AWS credential key id"
}

variable "aws_secret_access_key" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_SECRET"
  description = "AWS credential key secret"
}

variable "TELEGRAM_BOT_TOKEN_DEV" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_TELEGRAM_BOT_TOKEN"
  description = "Telegram bot token for the dev workspace"
}

variable "TELEGRAM_BOT_TOKEN_STAGE" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_TELEGRAM_BOT_TOKEN"
  description = "Telegram bot token for the staging workspace"
}

variable "TELEGRAM_BOT_TOKEN_PROD" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_TELEGRAM_BOT_TOKEN"
  description = "Telegram bot token for the production workspace"
}

variable "OPENWEATHERMAP_ORG_APP_ID" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_OPENWEATHERMAP_ORG_APP_ID"
  description = "OpenWeatherMap API ID"
}

variable "lambda_role_arn" {
  type        = string
  sensitive   = true
  default     = "TEST_DUMMY_LAMBDA_ROLE_ARN"
  description = "ARN of the Lambda execution role"
}

/*
variable "lambda_layer_arn" {
  description = "ARN of an existing, versioned Lambda layer"
  type        = string
}
*/
