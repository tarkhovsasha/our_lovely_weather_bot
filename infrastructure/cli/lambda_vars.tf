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
  cloud {
    organization = "telegram_weather_bot"
    workspaces {
      name = "cli-the-force-ws"
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

/*
# Package the Lambda function code on the fly
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content  = <<EOF
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Hello from HCP Terraform managed Lambda!'
    }
EOF
    filename = "index.py"
  }
}


# The AWS Lambda Function with Tags
resource "aws_lambda_function" "test_lambda" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "telegram-weather-bot-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.12"

  # Resource-level tags applied to the function
  tags = {
    Environment = var.environment
    project     = "our_lovely_weather_bot"
    ManagedBy   = "HCP-Terraform"
  }
}

resource "aws_lambda_function_url" "test_lambda_url" {
  function_name      = aws_lambda_function.test_lambda.function_name
  authorization_type = "NONE" # Change to "AWS_IAM" if you want to restrict public access

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

output "lambda_function_arn" {
  value       = aws_lambda_function.test_lambda.arn
  description = "The ARN of the newly created Lambda function."
}

output "lambda_tags" {
  value = aws_lambda_function.test_lambda.tags_all
}

# Output the live HTTP trigger URL
output "lambda_trigger_url" {
  value       = aws_lambda_function_url.test_lambda_url.function_url
  description = "The public HTTP(S) endpoint URL used to trigger the Lambda function."
}
*/