locals {
  weather_bot_source_hash = base64sha256(join(":", [
    filesha256("${path.module}/weather_bot_lambda.py"),
    filesha256("${path.module}/requirements.txt"),
  ]))
  environment_slug = lower(replace(var.environment, "_", "-"))
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "weather_bot" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "weather-bot-${local.environment_slug}-vpc"
    Environment = var.environment
    ManagedBy   = "HCP-Terraform"
  }
}

resource "aws_internet_gateway" "weather_bot" {
  vpc_id = aws_vpc.weather_bot.id

  tags = {
    Name        = "weather-bot-${local.environment_slug}-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.weather_bot.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name        = "weather-bot-${local.environment_slug}-public-subnet"
    Environment = var.environment
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.weather_bot.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name        = "weather-bot-${local.environment_slug}-private-subnet"
    Environment = var.environment
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.weather_bot.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.weather_bot.id
  }

  tags = {
    Name        = "weather-bot-${local.environment_slug}-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "weather-bot-${local.environment_slug}-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "weather_bot" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.weather_bot]

  tags = {
    Name        = "weather-bot-${local.environment_slug}-nat"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.weather_bot.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.weather_bot.id
  }

  tags = {
    Name        = "weather-bot-${local.environment_slug}-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.weather_bot.id
  service_name      = "com.amazonaws.${var.AWS_REGION}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = {
    Name        = "weather-bot-${local.environment_slug}-s3-endpoint"
    Environment = var.environment
  }
}

resource "aws_security_group" "lambda" {
  name        = "weather-bot-${local.environment_slug}-lambda"
  description = "Network access for the weather bot Lambda"
  vpc_id      = aws_vpc.weather_bot.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "weather-bot-${local.environment_slug}-lambda-sg"
    Environment = var.environment
  }
}

locals {
  static_resource_bucket_name = "static-resource-${local.environment_slug}-${data.aws_caller_identity.current.account_id}-${var.AWS_REGION}"
}

resource "aws_s3_bucket" "static_resource" {
  bucket = local.static_resource_bucket_name

  tags = {
    Name        = "static-resource-${local.environment_slug}"
    Environment = var.environment
    ManagedBy   = "HCP-Terraform"
  }
}

resource "aws_s3_bucket_versioning" "static_resource" {
  bucket = aws_s3_bucket.static_resource.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "static_resource" {
  bucket                  = aws_s3_bucket.static_resource.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_resource" {
  bucket = aws_s3_bucket.static_resource.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "DenyRequestsOutsideVpcEndpoint"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.static_resource.arn,
        "${aws_s3_bucket.static_resource.arn}/*",
      ]
      Condition = {
        StringNotEquals = {
          "aws:SourceVpce" = aws_vpc_endpoint.s3.id
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "weather_bot_access" {
  name = "weather-bot-${local.environment_slug}-vpc-s3-access"
  role = element(reverse(split("/", var.lambda_role_arn)), 0)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AssignPrivateIpAddresses",
          "ec2:UnassignPrivateIpAddresses",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = aws_s3_bucket.static_resource.arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${aws_s3_bucket.static_resource.arn}/*"
      },
    ]
  })
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
      REQUIREMENTS_FILE = "${path.module}/requirements.txt"
      HANDLER_FILE      = "${path.module}/weather_bot_lambda.py"
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

  vpc_config {
    subnet_ids         = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  depends_on = [
    terraform_data.weather_bot_package,
    aws_iam_role_policy.weather_bot_access,
    aws_route_table_association.private,
    aws_vpc_endpoint.s3,
    aws_s3_bucket_policy.static_resource,
  ]

  environment {
    variables = {
      LOG_LEVEL                 = "INFO"
      ENVIRONMENT               = "${var.environment}"
      OPENWEATHERMAP_ORG_APP_ID = "${var.OPENWEATHERMAP_ORG_APP_ID}"
      TELEGRAM_BOT_TOKEN        = "${var.TELEGRAM_BOT_TOKEN}"
      STATIC_RESOURCE_BUCKET    = aws_s3_bucket.static_resource.bucket
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

output "static_resource_bucket_name" {
  value       = aws_s3_bucket.static_resource.bucket
  description = "Environment-specific, VPC-restricted bucket for static image resources."
}

output "weather_bot_trigger_url" {
  value       = aws_lambda_function_url.weather_bot_url.function_url
  description = "The public URL used to trigger the weather bot Lambda function."
}