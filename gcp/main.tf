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
}

# =============================================================================
# NON-FREE RESOURCES - Uncomment to enable (will incur costs)
# =============================================================================

# Compute Engine instance for testing compute-based privilege escalation
# Estimated cost: ~$5/month for e2-micro
# module "compute" {
#   source = "./modules/non-free-resources/compute"
#
#   project_id      = var.gcp_project_id
#   region          = var.gcp_region
#   zone            = var.gcp_zone
#   attacker_member = local.attacker_member
#
#   # Pass the high-privilege service account from privesc-paths
#   high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
# }

# Cloud Functions for testing function-based privilege escalation
# Estimated cost: Free tier usually covers testing
# module "cloud-functions" {
#   source = "./modules/non-free-resources/cloud-functions"
#
#   project_id      = var.gcp_project_id
#   region          = var.gcp_region
#   attacker_member = local.attacker_member
#
#   high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
# }

# Cloud Run for testing container-based privilege escalation
# Estimated cost: Free tier usually covers testing
# module "cloud-run" {
#   source = "./modules/non-free-resources/cloud-run"
#
#   project_id      = var.gcp_project_id
#   region          = var.gcp_region
#   attacker_member = local.attacker_member
#
#   high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
# }
