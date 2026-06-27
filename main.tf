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

## Bucket separado y de lectura pública para las imágenes de productos. Se mantiene aparte del bucket
## de backups (db_storage) para no tener que tocar su política de acceso, que debe seguir 100% privada.
resource "aws_s3_bucket" "product_images" {
  bucket = var.images_bucket_name

  tags = {
    Purpose = "product-images"
  }
}

## Solo se relaja block_public_policy/restrict_public_buckets (necesarios para que la bucket policy de
## lectura pública surta efecto). Las ACLs públicas se mantienen bloqueadas: el acceso es vía policy.
resource "aws_s3_bucket_public_access_block" "product_images" {
  bucket = aws_s3_bucket.product_images.id

  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = false
}

## Policy de lectura pública: cualquiera puede hacer GET de los objetos (son fotos de productos, no datos sensibles).
resource "aws_s3_bucket_policy" "product_images_public_read" {
  bucket = aws_s3_bucket.product_images.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadProductImages"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.product_images.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.product_images]
}

## Sube todas las imágenes de Imagenes/ al bucket público, una por cada archivo encontrado.
resource "aws_s3_object" "product_images" {
  for_each = fileset("${path.module}/Imagenes", "*")

  bucket       = aws_s3_bucket.product_images.id
  key          = each.value
  source       = "${path.module}/Imagenes/${each.value}"
  etag         = filemd5("${path.module}/Imagenes/${each.value}")
  content_type = "image/jpeg"
}