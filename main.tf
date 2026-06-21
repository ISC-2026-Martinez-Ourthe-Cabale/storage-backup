resource "aws_s3_bucket" "db_storage" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "db_storage" {
  bucket = aws_s3_bucket.db_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "db_storage" {
  bucket = aws_s3_bucket.db_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "db_storage" {
  bucket = aws_s3_bucket.db_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "db_storage" {
  bucket = aws_s3_bucket.db_storage.id

  rule {
    id     = "backup-lifecycle"
    status = "Enabled"

    filter {
      prefix = "bkp-rds/"
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_object" "db_settings_sql" {
  bucket = aws_s3_bucket.db_storage.id
  key    = "db-settings/db-settings.sql"
  source = "${path.module}/db-settings.sql"

  etag = filemd5("${path.module}/db-settings.sql")
}