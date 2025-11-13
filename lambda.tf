# IAM Role for Lambda Function
resource "aws_iam_role" "lambda_role" {
  name = "${var.vpc_name}-lambda-email-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.vpc_name}-lambda-email-role"
  }
}

# IAM Policy for Lambda to write CloudWatch Logs
resource "aws_iam_policy" "lambda_logging" {
  name        = "${var.vpc_name}-lambda-logging-policy"
  description = "IAM policy for logging from Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      }
    ]
  })
}

# IAM Policy for Lambda to access DynamoDB
resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "${var.vpc_name}-lambda-dynamodb-policy"
  description = "IAM policy for Lambda to access DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.email_tracking.arn,
          "${aws_dynamodb_table.email_tracking.arn}/index/*"
        ]
      }
    ]
  })
}

# IAM Policy for Lambda to access Secrets Manager
resource "aws_iam_policy" "lambda_secrets" {
  name        = "${var.vpc_name}-lambda-secrets-policy"
  description = "IAM policy for Lambda to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.email_credentials.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.secrets_key.arn
      }
    ]
  })
}

# IAM Policy for Lambda to use SES (if using AWS SES for email)
resource "aws_iam_policy" "lambda_ses" {
  name        = "${var.vpc_name}-lambda-ses-policy"
  description = "IAM policy for Lambda to send emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_logging_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secrets.arn
}

resource "aws_iam_role_policy_attachment" "lambda_ses_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ses.arn
}

# Lambda Function
resource "aws_lambda_function" "email_verification" {
  filename         = var.lambda_zip_path
  function_name    = "${var.vpc_name}-email-verification"
  role             = aws_iam_role.lambda_role.arn
  handler          = "com.csye6225.lambda.EmailVerificationHandler::handleRequest"
  source_code_hash = filebase64sha256(var.lambda_zip_path)
  runtime          = "java17"
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.email_tracking.name
      EMAIL_SECRET_ARN    = aws_secretsmanager_secret.email_credentials.arn
      DOMAIN_NAME         = var.domain_name
      AWS_REGION_NAME     = var.aws_region
    }
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }

  tags = {
    Name = "${var.vpc_name}-email-verification"
  }
}

# Lambda permission for SNS to invoke
resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email_verification.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.user_verification.arn
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.email_verification.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${var.vpc_name}-lambda-logs"
  }
}

# Outputs
output "lambda_function_arn" {
  value       = aws_lambda_function.email_verification.arn
  description = "ARN of the Lambda function"
}

output "lambda_function_name" {
  value       = aws_lambda_function.email_verification.function_name
  description = "Name of the Lambda function"
}