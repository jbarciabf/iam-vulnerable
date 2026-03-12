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
  enable_privesc12  = var.enable_privesc12
  enable_privesc13  = var.enable_privesc13
  enable_privesc14  = var.enable_privesc14
  enable_lateral7   = var.enable_lateral7
  enable_privesc17  = var.enable_privesc17
  enable_privesc18  = var.enable_privesc18
  enable_privesc19  = var.enable_privesc19
  enable_privesc20  = var.enable_privesc20
  enable_privesc21  = var.enable_privesc21
  enable_privesc25  = var.enable_privesc25
  enable_privesc27  = var.enable_privesc27
  enable_privesc29  = var.enable_privesc29
  enable_privesc31  = var.enable_privesc31
  enable_privesc37  = var.enable_privesc37
  enable_privesc40  = var.enable_privesc40
  enable_privesc42  = var.enable_privesc42
  enable_privesc44  = var.enable_privesc44
  enable_privesc45  = var.enable_privesc45

  depends_on = [google_project_service.serviceusage]
}

module "tool-testing" {
  source = "./modules/free-resources/tool-testing"
  count  = var.enable_tool_testing ? 1 : 0

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

# Compute Engine instances for privesc11/12/13/14/lateral7 (setMetadata, osLogin, setServiceAccount, existingSSH)
# Created when any compute-based privesc path is enabled
# Cost: ~$6-7/month per e2-micro instance (standard)
module "compute" {
  source = "./modules/non-free-resources/compute"
  count  = (var.enable_privesc11 || var.enable_privesc12 || var.enable_privesc13 || var.enable_privesc14 || var.enable_lateral7) ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  zone            = var.gcp_zone
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email

  # Per-path instance flags
  enable_privesc11 = var.enable_privesc11
  enable_privesc12 = var.enable_privesc12
  enable_privesc13 = var.enable_privesc13
  enable_privesc14 = var.enable_privesc14
  enable_lateral7  = var.enable_lateral7
}

# Cloud Function for privesc17 (updateFunction)
# Created when function-based privesc path is enabled
# Cost: Free when idle (pay per invocation)
module "cloud-functions" {
  source = "./modules/non-free-resources/cloud-functions"
  count  = var.enable_privesc17 ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email
}

# Cloud Run infrastructure for privesc18/19/20/21 (run.services.create/update, run.jobs.create/update)
# Created when any Cloud Run privesc path is enabled
# Cost: < $0.10/month (Cloud Build, Artifact Registry, Cloud Run all have generous free tiers)
# Includes:
#   - Token-extractor container image (built via Cloud Build)
#   - Target Cloud Run service running as high-priv SA (path 19 only)
#   - Target Cloud Run job running as high-priv SA (path 21 only)
module "cloud-run" {
  source = "./modules/non-free-resources/cloud-run"
  count  = (var.enable_privesc18 || var.enable_privesc19 || var.enable_privesc20 || var.enable_privesc21) ? 1 : 0

  project_id      = var.gcp_project_id
  region          = var.gcp_region
  attacker_member = local.attacker_member

  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email

  # Pass SA emails for Artifact Registry access
  privesc18_sa_email = module.privesc-paths.privesc18_sa_email
  privesc19_sa_email = module.privesc-paths.privesc19_sa_email
  privesc20_sa_email = module.privesc-paths.privesc20_sa_email
  privesc21_sa_email = module.privesc-paths.privesc21_sa_email

  # Only create target service for path 19
  enable_privesc19 = var.enable_privesc19
  # Only create target job for path 21
  enable_privesc21 = var.enable_privesc21
}

# Cloud Scheduler job for privesc25 (cloudscheduler.jobs.update)
# Created when scheduler update privesc path is enabled
# Cost: Minimal (pay per job execution)
module "cloud-scheduler" {
  source = "./modules/non-free-resources/cloud-scheduler"
  count  = var.enable_privesc25 ? 1 : 0

  project_id = var.gcp_project_id
  region     = var.gcp_region

  depends_on = [module.privesc-paths]
}

# Deployment Manager deployment for privesc27 (deploymentmanager.deployments.update)
# Created when DM update privesc path is enabled
# Cost: ~$0.02/month (GCS bucket for placeholder deployment)
module "deployment-manager" {
  source = "./modules/non-free-resources/deployment-manager"
  count  = var.enable_privesc27 ? 1 : 0

  project_id = var.gcp_project_id

  depends_on = [module.privesc-paths]
}

# Cloud Composer environment for privesc29 (composer.environments.update)
# Created when composer update privesc path is enabled
# ⚠️  EXTREME COST WARNING: ~$400/month! DELETE IMMEDIATELY after testing!
module "composer" {
  source = "./modules/non-free-resources/composer"
  count  = var.enable_privesc29 ? 1 : 0

  project_id         = var.gcp_project_id
  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email

  depends_on = [module.privesc-paths]
}

# Dataflow streaming job for privesc31 (dataflow.jobs.updateContents)
# Created when dataflow update privesc path is enabled
# Cost: ~$0.05-0.10/hr while running
module "dataflow" {
  source = "./modules/non-free-resources/dataflow"
  count  = var.enable_privesc31 ? 1 : 0

  project_id         = var.gcp_project_id
  region             = var.gcp_region
  high_priv_sa_email = module.privesc-paths.high_priv_service_account_email

  depends_on = [module.privesc-paths]
}
