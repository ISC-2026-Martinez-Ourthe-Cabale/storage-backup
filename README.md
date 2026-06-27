# 💾 storage-backup

**Repositorio:** `ISC-2026-Martinez-Ourthe-Cabale/storage-backup`
**Lenguaje:** HCL (Terraform)

## Descripción

Este módulo aprovisiona **dos buckets S3 con propósitos y niveles de acceso distintos**:

1. **Bucket de backups (`db_storage`)** — privado, para backups de la base de datos y el script de inicialización (`db-settings.sql`).
2. **Bucket de imágenes de productos (`product_images`)** — público de solo lectura, para servir las fotos de productos del catálogo vía URL HTTPS directa.

Se mantienen como buckets separados a propósito: el bucket de backups nunca se expone públicamente, y solo el bucket de imágenes (que no contiene datos sensibles) relaja el bloqueo de acceso público.

## Recursos Creados

| Recurso AWS                                          | Bucket           | Descripción                                                                 |
| ----------------------------------------------------- | ---------------- | ---------------------------------------------------------------------------- |
| `aws_s3_bucket.db_storage`                           | backups          | Bucket privado para backups y `db-settings.sql`                            |
| `aws_s3_bucket_public_access_block.db_storage`       | backups          | Bloquea todo acceso público (los 4 flags en `true`)                        |
| `aws_s3_bucket_server_side_encryption_configuration` | backups          | Cifrado en reposo con AES256                                               |
| `aws_s3_bucket_versioning.db_storage`                | backups          | Versionado habilitado                                                      |
| `aws_s3_bucket_lifecycle_configuration.db_storage`    | backups          | Transiciona objetos bajo `bkp-rds/` a IA (30d) y Glacier (90d), expira a 365d |
| `aws_s3_object.db_settings_sql`                      | backups          | Sube `db-settings.sql` a la key `db-settings/db-settings.sql`               |
| `aws_s3_bucket.product_images`                       | imágenes         | Bucket público de solo lectura para fotos de productos                     |
| `aws_s3_bucket_public_access_block.product_images`   | imágenes         | Solo relaja `block_public_policy`/`restrict_public_buckets`; las ACLs públicas siguen bloqueadas |
| `aws_s3_bucket_policy.product_images_public_read`    | imágenes         | Policy que permite `s3:GetObject` público sobre todos los objetos          |
| `aws_s3_object.product_images`                       | imágenes         | Sube cada archivo de `Imagenes/` (vía `fileset`), uno por producto         |

## Variables de Entrada

| Variable             | Tipo     | Descripción                                                              |
| --------------------- | -------- | --------------------------------------------------------------------------- |
| `bucket_name`        | `string` | Nombre del bucket de backups. Debe ser globalmente único dentro de AWS    |
| `images_bucket_name` | `string` | Nombre del bucket público de imágenes. También debe ser globalmente único |

## Outputs

| Output              | Descripción                                                          |
| --------------------- | ----------------------------------------------------------------------- |
| `images_bucket_name` | Nombre del bucket público de imágenes de productos                    |
| `images_base_url`    | URL base HTTPS del bucket de imágenes (sin slash final), para componer la URL de cada producto |

## Ejemplo de Uso

```hcl
module "db_storage" {
  source = "git::ssh://git@github.com/ISC-2026-Martinez-Ourthe-Cabale/storage-backup.git"

  bucket_name        = "obligatorio-backup-2026"
  images_bucket_name = "obligatorio-backup-2026-images"
}
```

## Imágenes de productos

Las imágenes a subir viven en `Imagenes/` dentro de este mismo repositorio. Cualquier archivo agregado ahí se sube automáticamente al bucket público en el siguiente `terraform apply` (la key en S3 es el nombre de archivo tal cual). El módulo `modules-ec2-tmp` consume el output `images_base_url` para completar el campo `images` de cada producto con la URL pública correspondiente.

## Consideraciones de seguridad

* **Bucket de backups:** privado, cifrado, versionado. El acceso público está bloqueado por completo (los 4 flags en `true`).
* **Bucket de imágenes:** intencionalmente público — son fotos de productos del catálogo, no datos sensibles. Solo se relaja `block_public_policy`/`restrict_public_buckets`; el bloqueo de ACLs públicas se mantiene, el acceso es exclusivamente vía bucket policy.
* **State file:** el estado de Terraform (`terraform.tfstate`) puede contener referencias a estos buckets. Configurar un backend remoto para entornos compartidos.
