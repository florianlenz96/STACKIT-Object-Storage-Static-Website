# Static Website on STACKIT Object Storage + CDN

A demo showing how to host a static portfolio website on **STACKIT Object Storage**, served via **STACKIT CDN**, with optional custom domain and managed TLS — all deployed with Terraform.

```
stack-static-website-storage/
├── website/
│   ├── index.html          # Portfolio page (Hero, About, Skills, Projects, Contact)
│   └── css/
│       └── style.css       # Responsive dark-theme CSS
├── terraform/
│   ├── providers.tf        # STACKIT + null provider configuration
│   ├── variables.tf        # Variable definitions
│   ├── terraform.tfvars.example  # Configuration template
│   ├── main.tf             # Bucket, credentials, CDN, custom domain
│   └── outputs.tf          # Website URL and CDN info
└── .gitignore
```

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.3 | `brew install terraform` |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | v2 | `brew install awscli` |
| STACKIT Account | — | [stackit.de](https://stackit.de) |

> The AWS CLI is used only for S3-compatible file uploads. No AWS account is needed.

---

## Setup

### 1. Authenticate with STACKIT

Export your service account key path as an environment variable — the STACKIT provider picks it up automatically:

```bash
export STACKIT_SERVICE_ACCOUNT_KEY_PATH=/path/to/service-account-key.json
```

> To create a service account key: [STACKIT Portal](https://portal.stackit.cloud) → your project → **Service Accounts** → create SA with **Object Storage Admin** + **CDN Admin** roles → download key JSON.

### 2. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
stackit_project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"  # Your project UUID
bucket_name        = "my-portfolio-website"                   # Globally unique, DNS-compatible
stackit_region     = "eu01"
```

> ⚠️ `terraform.tfvars` is listed in `.gitignore` — never commit it.

---

## Deployment

```bash
cd terraform
terraform init
terraform apply
```

After a successful apply, Terraform prints the outputs:

```
Outputs:

cdn_managed_domain    = "abc123.cdn.onstackit.cloud"
website_url           = "abc123.cdn.onstackit.cloud/index.html"
cdn_custom_domain_url = "Not configured — set the custom_domain variable and re-apply."
bucket_name           = "my-portfolio-website"
```

---

## Custom Domain (optional)

Attaching a custom domain to the CDN is a **two-step process** because your DNS provider must have the CNAME record in place before STACKIT can provision the managed TLS certificate.

### Step 1 — Deploy and get the CDN managed domain

Run the initial deployment (without `custom_domain` set). Note the `cdn_managed_domain` output:

```
cdn_managed_domain = "abc123.cdn.onstackit.cloud"
```

### Step 2 — Create a CNAME record at your DNS provider

At your DNS provider (Route 53, IONOS, etc.), create:

| Type | Name | Value |
|------|------|-------|
| CNAME | `cdn.yourdomain.com` | `abc123.cdn.onstackit.cloud` |

### Step 3 — Set the custom domain and re-apply

Add to `terraform.tfvars`:

```hcl
custom_domain = "cdn.yourdomain.com"
```

Then re-apply:

```bash
terraform apply
```

STACKIT will provision and manage the TLS certificate automatically. The output will show:

```
cdn_custom_domain_url = "https://cdn.yourdomain.com"
```

---

## Updating the Website

Edit any file in `website/`, then re-run:

```bash
terraform apply
```

Terraform detects file changes via SHA-256 hash and re-syncs the bucket automatically.

---

## Teardown

```bash
terraform destroy
```

> Note: The bucket must be empty before Terraform can delete it. If `terraform destroy` fails, manually empty the bucket first:
> ```bash
> aws s3 rm s3://my-portfolio-website/ --recursive \
>   --endpoint-url https://object.storage.eu01.onstackit.cloud
> ```

---

## How It Works

1. **`stackit_objectstorage_bucket`** — Creates the private bucket in STACKIT Object Storage
2. **`stackit_objectstorage_credentials_group` + `stackit_objectstorage_credential`** — Generates S3-compatible access keys
3. **`null_resource` (local-exec)** — Uses the AWS CLI to sync `website/` files to the bucket
4. **`stackit_cdn_distribution`** — Creates a CDN distribution with the bucket as origin (using credentials — no public bucket access needed)
5. **`stackit_cdn_custom_domain`** *(optional)* — Attaches a custom domain with STACKIT-managed TLS cert
