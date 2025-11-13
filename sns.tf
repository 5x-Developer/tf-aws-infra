# SNS Topic for user verification emails
resource "aws_sns_topic" "user_verification" {
  name              = "${var.vpc_name}-user-verification"
  display_name      = "User Email Verification"
  kms_master_key_id = aws_kms_key.secrets_key.id

  tags = {
    Name = "${var.vpc_name}-user-verification"
  }
}

# SNS Topic Policy to allow EC2 instances to publish
resource "aws_sns_topic_policy" "user_verification_policy" {
  arn = aws_sns_topic.user_verification.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2Publish"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.s3_role.arn
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.user_verification.arn
      },
      {
        Sid    = "AllowLambdaSubscribe"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "SNS:Subscribe",
          "SNS:Receive"
        ]
        Resource = aws_sns_topic.user_verification.arn
      }
    ]
  })
}

# SNS Topic Subscription for Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.user_verification.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.email_verification.arn
}

# Output
output "sns_topic_arn" {
  value       = aws_sns_topic.user_verification.arn
  description = "ARN of the user verification SNS topic"
}

output "sns_topic_name" {
  value       = aws_sns_topic.user_verification.name
  description = "Name of the user verification SNS topic"
}