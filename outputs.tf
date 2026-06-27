## Output con el nombre del bucket público de imágenes de productos.
output "images_bucket_name" {
  description = "Nombre del bucket S3 público de imágenes de productos."
  value       = aws_s3_bucket.product_images.id
}

## Output con la URL base (HTTPS, sin slash final) del bucket de imágenes, para componer URLs de objetos.
output "images_base_url" {
  description = "URL base HTTPS del bucket de imágenes de productos."
  value       = "https://${aws_s3_bucket.product_images.bucket_regional_domain_name}"
}
