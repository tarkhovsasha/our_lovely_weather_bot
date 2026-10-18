terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

# Variable configuration allowing easy overrides in HCP Terraform
variable "AWS_REGION" {
  type    = string
  default = "us-west-2"
}

variable "lambda_role_arn" {
  type = string
}

/*
variable "lambda_layer_arn" {
  type = string
}
*/

variable "TELEGRAM_BOT_TOKEN" {
  type      = string
  sensitive = true
}

variable "OPENWEATHERMAP_ORG_APP_ID" {
  type      = string
  sensitive = true
}

variable "environment" {
  type    = string
  default = "testing"
}

provider "aws" {
  region = var.AWS_REGION
}
