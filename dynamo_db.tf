# DynamoDB table to track sent emails and prevent duplicates
resource "aws_dynamodb_table" "email_tracking" {
  name         = "${var.vpc_name}-email-tracking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "email"
  range_key    = "message_id"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "message_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  global_secondary_index {
    name            = "timestamp-index"
    hash_key        = "email"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.secrets_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name = "${var.vpc_name}-email-tracking"
  }
}

# Output
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.email_tracking.name
  description = "Name of the email tracking DynamoDB table"
}

output "dynamodb_table_arn" {
  value       = aws_dynamodb_table.email_tracking.arn
  description = "ARN of the email tracking DynamoDB table"
}