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

# Get current project information
data "google_project" "current" {
  project_id = var.gcp_project_id
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
# NON-FREE RESOURCES - Enable via variables (will incur costs)
# =============================================================================

# Compute Engine instance for testing compute-based privilege escalation
# Enable with: enable_compute = true
# Cost: ~$2-3/month (preemptible)
module "compute" {
  source = "./modules/non-free-resources/compute"
  count  = var.enable_compute ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  zone            = var.gcp_zone
  attacker_member = local.attacker_member

  # Pass the high-privilege service account from privesc-paths
  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}

# Cloud Functions for testing function-based privilege escalation
# Enable with: enable_cloud_functions = true
# Cost: Free tier usually covers testing
module "cloud-functions" {
  source = "./modules/non-free-resources/cloud-functions"
  count  = var.enable_cloud_functions ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}

# Cloud Run for testing container-based privilege escalation
# Enable with: enable_cloud_run = true
# Cost: Free tier usually covers testing
module "cloud-run" {
  source = "./modules/non-free-resources/cloud-run"
  count  = var.enable_cloud_run ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}
