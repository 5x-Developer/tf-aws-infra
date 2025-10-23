resource "random_uuid" "s3_bucket_names" {
}

resource "aws_s3_bucket" "bucket" {
  bucket        = random_uuid.s3_bucket_names.result
  force_destroy = true

}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket_encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

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
