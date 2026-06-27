# 💾 storage-backup

**Repositorio:** `ISC-2026-Martinez-Ourthe-Cabale/storage-backup`
**Lenguaje:** HCL (Terraform)

## Descripción

Este módulo aprovisiona y configura un bucket de Amazon S3 destinado al almacenamiento de backups y archivos utilizados por la aplicación.

El bucket puede emplearse para almacenar:

* Backups de bases de datos.
* Archivos generados por la aplicación.
* Datos persistentes requeridos por otros componentes de la infraestructura.

## Recursos Creados

| Recurso AWS     | Descripción                                                        |
| --------------- | ------------------------------------------------------------------ |
| `aws_s3_bucket` | Bucket Amazon S3 destinado al almacenamiento de backups y archivos |

## Variables de Entrada

| Variable      | Tipo     | Descripción                                                 |
| ------------- | -------- | ----------------------------------------------------------- |
| `bucket_name` | `string` | Nombre del bucket. Debe ser globalmente único dentro de AWS |

## Ejemplo de Uso

```hcl
module "db_storage" {
  source = "git::ssh://git@github.com/ISC-2026-Martinez-Ourthe-Cabale/storage-backup.git"

  bucket_name = "obligatorio-backup-2026"
}
```

## Consideraciones

> **Importante:** El nombre del bucket S3 debe ser único a nivel global en toda AWS. Se recomienda incluir el nombre del proyecto junto con un identificador único, como el ID de cuenta, la fecha o el entorno.

Ejemplos:

* `obligatorio-backup-2026`
* `ecommerce-prod-123456789012`
* `isc-backups-dev-2026`

## Recomendaciones para Producción

Para entornos productivos se recomienda habilitar las siguientes características:

* **Versionado del bucket**, para conservar versiones anteriores de los objetos.
* **Cifrado en reposo**, para proteger la información almacenada.
* **Políticas de ciclo de vida (Lifecycle Rules)**, para optimizar costos mediante archivado o eliminación automática de objetos antiguos.
* **Bloqueo de acceso público**, para evitar exposiciones accidentales de datos.
