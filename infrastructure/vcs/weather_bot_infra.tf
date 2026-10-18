locals {
  weather_bot_source_hash = base64sha256(join(":", [
    filesha256("${path.module}/../../weather_bot_lambda.py"),
    filesha256("${path.module}/../../requirements.txt"),
  ]))
}

resource "terraform_data" "weather_bot_package" {
  triggers_replace = [local.weather_bot_source_hash]

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      mkdir -p "$PACKAGE_DIR"
      python3 -m pip install \
        --disable-pip-version-check \
        --only-binary=:all: \
        --platform manylinux2014_x86_64 \
        --implementation cp \
        --python-version 3.12 \
        --target "$PACKAGE_DIR" \
        -r "$REQUIREMENTS_FILE"
      cp "$HANDLER_FILE" "$PACKAGE_DIR/"
      python3 - "$PACKAGE_DIR" "$ZIP_PATH" <<'PY'
      import os
      import sys
      import zipfile

      package_dir, zip_path = sys.argv[1:]
      with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as package:
          for root, _, files in os.walk(package_dir):
              for filename in files:
                  path = os.path.join(root, filename)
                  package.write(path, os.path.relpath(path, package_dir))
      PY
    EOT

    environment = {
      PACKAGE_DIR       = "${path.module}/build/weather_bot"
      ZIP_PATH          = "${path.module}/weather_bot_lambda.zip"
      REQUIREMENTS_FILE = "${path.module}/../../requirements.txt"
      HANDLER_FILE      = "${path.module}/../../weather_bot_lambda.py"
    }
  }
}

resource "aws_lambda_function" "weather_bot" {
  filename         = "${path.module}/weather_bot_lambda.zip"
  function_name    = "telegram-weather-bot-app-${var.environment}"
  role             = var.lambda_role_arn
  handler          = "weather_bot_lambda.lambda_handler"
  source_code_hash = local.weather_bot_source_hash
  runtime          = "python3.12"

  depends_on = [terraform_data.weather_bot_package]

  environment {
    variables = {
      LOG_LEVEL                 = "INFO"
      ENVIRONMENT               = "${var.environment}"
      OPENWEATHERMAP_ORG_APP_ID = "${var.OPENWEATHERMAP_ORG_APP_ID}"
      TELEGRAM_BOT_TOKEN        = "${var.TELEGRAM_BOT_TOKEN}"
    }
  }

  tags = {
    Environment = var.environment
    project     = "our_lovely_weather_bot"
    ManagedBy   = "HCP-Terraform"
  }
}



resource "aws_lambda_function_url" "weather_bot_url" {
  function_name      = aws_lambda_function.weather_bot.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}

resource "terraform_data" "telegram_webhook" {
  triggers_replace = [
    aws_lambda_function_url.weather_bot_url.function_url,
    sha256(var.TELEGRAM_BOT_TOKEN),
  ]

  provisioner "local-exec" {
    command = <<-EOT
      curl --fail --silent --show-error --request POST \
        --data-urlencode "url=$AWS_LAMBDA_URL" \
        "https://api.telegram.org/bot$TG_BOT_TOKEN/setWebhook"
    EOT

    environment = {
      AWS_LAMBDA_URL = aws_lambda_function_url.weather_bot_url.function_url
      TG_BOT_TOKEN   = var.TELEGRAM_BOT_TOKEN
    }
  }
}

output "weather_bot_lambda_arn" {
  value       = aws_lambda_function.weather_bot.arn
  description = "The ARN of the weather bot Lambda function."
}

output "weather_bot_trigger_url" {
  value       = aws_lambda_function_url.weather_bot_url.function_url
  description = "The public URL used to trigger the weather bot Lambda function."
}