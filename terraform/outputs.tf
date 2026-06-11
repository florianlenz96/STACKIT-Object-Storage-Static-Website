output "website_url" {
  description = "Direct URL to the hosted website via CDN (use this after CDN is provisioned)."
  value       = "${stackit_cdn_distribution.website.domains[0].name}/index.html"
}

output "cdn_managed_domain" {
  description = "The CDN's auto-assigned managed domain. Create a CNAME record pointing your custom domain here before setting the custom_domain variable."
  value       = stackit_cdn_distribution.website.domains[0].name
}

output "bucket_name" {
  description = "Name of the created Object Storage bucket."
  value       = stackit_objectstorage_bucket.website.name
}

output "s3_access_key" {
  description = "S3 access key ID for the website bucket."
  value       = stackit_objectstorage_credential.website.access_key
}

output "s3_secret_key" {
  description = "S3 secret access key for the website bucket."
  value       = stackit_objectstorage_credential.website.secret_access_key
  sensitive   = true
}
