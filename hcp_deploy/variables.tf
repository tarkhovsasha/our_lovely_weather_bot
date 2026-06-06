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

variable "vcs_repo_branch" {
  type    = string
  default = "main"
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

variable "vcs_workspace_name" {
  type        = string
  default     = "the-force-ws"
  description = "Name of the VCS workspace."

  validation {
    condition     = length(var.vcs_workspace_name) > 4
    error_message = "The workspace name value must be longer than 4 characters."
  }
}

variable "cli_workspaces_name_list" {
  type        = list(string)
  default     = ["team-empire-ws", "team-republic-ws", "team-jedi-ws"]
  description = "List of CLI workspace names."

  validation {
    condition = alltrue([
      for str in var.cli_workspaces_name_list : str != ""
    ]) && length(var.cli_workspaces_name_list) == length(distinct([
      for str in var.cli_workspaces_name_list : lower(str)
    ]))
    error_message = "All names must be non-empty and unique."
  }
}

variable "default_aws_region" {
  type        = string
  default     = "eu-central-1"
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

/* variable "gitlab_group_path" {
  type        = string
  description = "Value for the full_path attribute of the gitlab_group resource to add the new app repo to"
} */