# GCP IAM Vulnerable - Intentionally Vulnerable GCP IAM Configurations
#
# This Terraform configuration creates intentionally vulnerable GCP IAM
# configurations for learning and security tool testing purposes.
#
# WARNING: These resources are intentionally insecure. Only deploy in
# isolated test projects that contain no sensitive data.

terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# =============================================================================
# PROJECT CREATION (Optional)
# =============================================================================
# If create_project = true, create the project. Otherwise, use existing.

resource "google_project" "this" {
  count = var.create_project ? 1 : 0

  name            = var.gcp_project_id
  project_id      = var.gcp_project_id
  billing_account = var.billing_account
  org_id          = var.gcp_organization_id != "" ? var.gcp_organization_id : null

  lifecycle {
    precondition {
      condition     = var.billing_account != ""
      error_message = "billing_account is required when create_project = true. Find yours with: gcloud billing accounts list"
    }
  }
}

# Enable Service Usage API first (required to enable other APIs)
resource "google_project_service" "serviceusage" {
  count = var.create_project ? 1 : 0

  project = google_project.this[0].project_id
  service = "serviceusage.googleapis.com"

  disable_on_destroy = false
}

# Get current project information
data "google_project" "current" {
  project_id = var.gcp_project_id

  depends_on = [google_project.this]
}

# Get current user's email for default attacker identity
data "google_client_openid_userinfo" "me" {}

# Local values for computed defaults
locals {
  # Default attacker member to current user if not specified
  attacker_member = var.attacker_member != "" ? var.attacker_member : "user:${data.google_client_openid_userinfo.me.email}"

  # Project number for certain resource references
  project_number = data.google_project.current.number
}

# =============================================================================
# FREE RESOURCES - Enabled by default (no additional cost beyond IAM)
# =============================================================================

module "privesc-paths" {
  source = "./modules/free-resources/privesc-paths"

  project_id      = var.gcp_project_id
  project_number  = local.project_number
  region          = var.gcp_region
  attacker_member = local.attacker_member

  # Individual privesc path toggles (disabled by default)
  enable_privesc11 = var.enable_privesc11
  enable_privesc12 = var.enable_privesc12
  enable_privesc13 = var.enable_privesc13
  enable_privesc16 = var.enable_privesc16
  enable_privesc17 = var.enable_privesc17
  enable_privesc19 = var.enable_privesc19
  enable_privesc42 = var.enable_privesc42

  depends_on = [google_project_service.serviceusage]
}

module "tool-testing" {
  source = "./modules/free-resources/tool-testing"

  project_id      = var.gcp_project_id
  project_number  = local.project_number
  region          = var.gcp_region
  attacker_member = local.attacker_member

  # Run after privesc-paths to avoid service account creation rate limits
  depends_on = [module.privesc-paths]
}

# =============================================================================
# TARGET INFRASTRUCTURE - Created when corresponding privesc paths are enabled
# =============================================================================

# Compute Engine instance for privesc11/12/13 (setMetadata, osLogin, setServiceAccount)
# Created when any compute-based privesc path is enabled
# Cost: ~$2-5/month (preemptible e2-micro)
module "compute" {
  source = "./modules/non-free-resources/compute"
  count  = (var.enable_privesc11 || var.enable_privesc12 || var.enable_privesc13) ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  zone            = var.gcp_zone
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}

# Cloud Function for privesc16/17 (updateFunction, sourceCodeSet)
# Created when any function-based privesc path is enabled
# Cost: Free when idle (pay per invocation)
module "cloud-functions" {
  source = "./modules/non-free-resources/cloud-functions"
  count  = (var.enable_privesc16 || var.enable_privesc17) ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}

# Cloud Run service for privesc19 (run.services.update)
# Created when Cloud Run privesc path is enabled
# Cost: Free when idle (scales to zero)
module "cloud-run" {
  source = "./modules/non-free-resources/cloud-run"
  count  = var.enable_privesc19 ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}
