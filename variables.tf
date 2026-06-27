variable "bucket_name" {
  type = string
}

## Variable para el nombre del bucket S3 público donde se alojan las imágenes de productos.
variable "images_bucket_name" {
  description = "Nombre del bucket S3 público donde se suben las imágenes de productos (lectura pública, separado del bucket de backups)."
  type        = string
}