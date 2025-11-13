# Get current AWS account ID
data "aws_caller_identity" "current" {}

# KMS Key for EC2 EBS Volumes
resource "aws_kms_key" "ec2_key" {
  description             = "KMS key for EC2 EBS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  # Add policy to allow Auto Scaling service to use the key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Auto Scaling to use the key"
        Effect = "Allow"
        Principal = {
          Service = "autoscaling.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow EC2 service to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "ec2-ebs-key"
  }
}

resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-ebs-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

# KMS Key for RDS
resource "aws_kms_key" "rds_key" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = {
    Name = "rds-key"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

# KMS Key for S3 Buckets
resource "aws_kms_key" "s3_key" {
  description             = "KMS key for S3 bucket encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = {
    Name = "s3-key"
  }
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

# KMS Key for Secrets Manager
resource "aws_kms_key" "secrets_key" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  rotation_period_in_days = 90

  tags = {
    Name = "secrets-manager-key"
  }
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-manager-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# Outputs for use in other resources
output "ec2_kms_key_id" {
  value       = aws_kms_key.ec2_key.id
  description = "KMS key ID for EC2"
}

output "rds_kms_key_id" {
  value       = aws_kms_key.rds_key.id
  description = "KMS key ID for RDS"
}

output "s3_kms_key_id" {
  value       = aws_kms_key.s3_key.id
  description = "KMS key ID for S3"
}

output "secrets_kms_key_id" {
  value       = aws_kms_key.secrets_key.id
  description = "KMS key ID for Secrets Manager"
}