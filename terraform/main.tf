locals {
  s3_endpoint = "https://object.storage.eu01.onstackit.cloud"
  website_dir = "${path.module}/../website"
}

resource "stackit_objectstorage_bucket" "website" {
  project_id = var.stackit_project_id
  name       = var.bucket_name
}

resource "stackit_objectstorage_credentials_group" "website" {
  depends_on = [stackit_objectstorage_bucket.website]

  project_id = var.stackit_project_id
  name       = "${substr(var.bucket_name, 0, 25)}-cred"
}

resource "stackit_objectstorage_credential" "website" {
  project_id           = var.stackit_project_id
  credentials_group_id = stackit_objectstorage_credentials_group.website.credentials_group_id
}

resource "null_resource" "website_deploy" {
  depends_on = [stackit_objectstorage_credential.website]

  triggers = {
    bucket_name  = var.bucket_name
    website_hash = sha256(join("", [
      for f in sort(fileset(local.website_dir, "**/*")) :
      filesha256("${local.website_dir}/${f}")
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      aws s3 sync ${local.website_dir}/ s3://${var.bucket_name}/ \
        --endpoint-url ${local.s3_endpoint} \
        --region ${var.stackit_region} \
        --delete
    EOT

    environment = {
      AWS_ACCESS_KEY_ID     = stackit_objectstorage_credential.website.access_key
      AWS_SECRET_ACCESS_KEY = stackit_objectstorage_credential.website.secret_access_key
      AWS_DEFAULT_REGION    = var.stackit_region
    }
  }
}

resource "stackit_cdn_distribution" "website" {
  depends_on = [stackit_objectstorage_credential.website]

  project_id = var.stackit_project_id

  config = {
    backend = {
      type       = "bucket"
      bucket_url = stackit_objectstorage_bucket.website.url_virtual_hosted_style
      region     = var.stackit_region
      credentials = {
        access_key_id     = stackit_objectstorage_credential.website.access_key
        secret_access_key = stackit_objectstorage_credential.website.secret_access_key
      }
    }

    regions           = ["EU"]
    blocked_countries = []
  }
}