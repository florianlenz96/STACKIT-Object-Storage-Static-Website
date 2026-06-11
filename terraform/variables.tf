variable "stackit_project_id" {
  description = "The STACKIT project ID (UUID) where resources will be created."
  type        = string
}

variable "bucket_name" {
  description = "Name of the Object Storage bucket. Must be globally unique and DNS-compatible (lowercase, no underscores)."
  type        = string
}

variable "stackit_region" {
  description = "STACKIT region to deploy resources in."
  type        = string
  default     = "eu01"
}

variable "custom_domain" {
  description = <<-EOT
    Custom domain to attach to the CDN distribution (e.g. "cdn.yourdomain.com").
    Leave unset for the first apply — after creating the CDN, Terraform outputs the
    managed CDN domain. Create a CNAME record at your DNS provider pointing to it,
    then set this variable and re-apply to provision the custom domain + managed TLS cert.
  EOT
  type    = string
  default = null
}
