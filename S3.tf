# S3 Bucket 
resource "random_uuid" "s3_bucket_names" {
}

resource "aws_s3_bucket" "bucket" {
  bucket        = random_uuid.s3_bucket_names.result
  force_destroy = true

  tags = {
    Name = "${var.vpc_name}-app-bucket"
  }
}

# Server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_key.arn
    }
    bucket_key_enabled = true
  }
}

# Lifecycle Configuration 
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle_of_bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "transition_rule"
    status = "Enabled"

    filter {}

    transition {
      storage_class = "STANDARD_IA"
      days          = 30
    }
  }
}

#  Enable versioning 
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access 
resource "aws_s3_bucket_public_access_block" "bucket_public_access_block" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Output
output "s3_bucket_name" {
  value       = aws_s3_bucket.bucket.bucket
  description = "Name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.bucket.arn
  description = "ARN of the S3 bucket"
}