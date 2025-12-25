terraform {
  required_version = ">= 1.14.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.15"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.9"
    }
    onepassword = {
      source  = "1Password/onepassword"
      version = "~> 3.0"
    }
  }

  # Cloudflare R2 backend (S3-compatible)
  # Credentials via AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY env vars
  backend "s3" {
    bucket = "signalstratum-tfstate"
    key    = "infrastructure/terraform.tfstate"
    region = "auto"

    # R2-specific settings
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true

    # R2 endpoint - set via AWS_ENDPOINT_URL_S3 env var
  }
}

provider "cloudflare" {
  # CLOUDFLARE_API_TOKEN env var set by 1Password GitHub Action
}

provider "github" {
  owner = "signalstratum"
  # GITHUB_TOKEN env var set by 1Password GitHub Action
}

provider "onepassword" {
  # OP_SERVICE_ACCOUNT_TOKEN env var for service account auth
  # Or OP_CONNECT_HOST + OP_CONNECT_TOKEN for Connect server
}
