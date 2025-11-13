# Store RDS credentials in Secrets Manager
resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${var.vpc_name}-rds-credentials-v6"
  description             = "RDS database credentials"
  kms_key_id              = aws_kms_key.secrets_key.id
  recovery_window_in_days = 7

  tags = {
    Name = "${var.vpc_name}-rds-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = var.db_user
    password = var.db_password
    host     = aws_db_instance.MySQL_DB.address
    port     = aws_db_instance.MySQL_DB.port
    dbname   = var.db_name
  })
}

# Store Email Service credentials in Secrets Manager
resource "aws_secretsmanager_secret" "email_credentials" {
  name                    = "${var.vpc_name}-email-credentials-v6"
  description             = "Email service API credentials"
  kms_key_id              = aws_kms_key.secrets_key.id
  recovery_window_in_days = 7

  tags = {
    Name = "${var.vpc_name}-email-credentials"
  }
}

# Placeholder - you'll update this with actual credentials after creation
resource "aws_secretsmanager_secret_version" "email_credentials" {
  secret_id = aws_secretsmanager_secret.email_credentials.id
  secret_string = jsonencode({
    api_key      = var.email_api_key
    service_name = var.email_service_name
    from_email   = var.email_from_address
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Outputs
output "rds_secret_arn" {
  value       = aws_secretsmanager_secret.rds_credentials.arn
  description = "ARN of RDS credentials secret"
  sensitive   = true
}

output "email_secret_arn" {
  value       = aws_secretsmanager_secret.email_credentials.arn
  description = "ARN of email service credentials secret"
  sensitive   = true
}