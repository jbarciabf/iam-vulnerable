# Privesc Path 28: Deployment Manager Update (Hijack Existing Deployment)
#
# VULNERABILITY: A service account with deploymentmanager.deployments.update and
# actAs can modify existing deployments to add resources running with a high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find an existing Deployment Manager deployment
#   3. Update it to add a new resource (VM) with high-priv SA attached
#   4. Access the deployed resource to get high-priv SA credentials
#
# DETECTION: FoxMapper detects this via the deploymentManager edge checker
#
# REAL-WORLD IMPACT: High - Hijack existing IaC deployments
#
# NOTE: Deployment Manager will reach end of support on March 31, 2026
#
# COST: ~$0.02/month (GCS bucket for target deployment)
#
# DISABLED BY DEFAULT: Set enable_privesc28 = true to enable
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - deploymentmanager.deployments.update (NO create needed!)
#   Supporting (Required for exploitation):
#     - deploymentmanager.deployments.get (to view deployment)
#     - deploymentmanager.operations.get (to monitor update)

resource "google_service_account" "privesc28_dm_update" {
  count = var.enable_privesc28 ? 1 : 0

  account_id   = "${var.resource_prefix}28-dm-update"
  display_name = "Privesc28 - Deployment Manager Update"
  description  = "Can escalate via deploymentmanager.deployments.update (no create)"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with UPDATE but NO CREATE
resource "google_project_iam_custom_role" "privesc28_dm_update" {
  count = var.enable_privesc28 ? 1 : 0

  role_id     = "${var.resource_prefix}_28_dm_update"
  title       = "Privesc28 - Deployment Manager Update Only"
  description = "Vulnerable: Can update (but NOT create) Deployment Manager deployments"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable) - NO create!
    "deploymentmanager.deployments.update",
    # Supporting permissions
    "deploymentmanager.deployments.get",
    "deploymentmanager.deployments.list",
    "deploymentmanager.operations.get",
    "deploymentmanager.operations.list",
    "deploymentmanager.manifests.get",
    "deploymentmanager.manifests.list",
    "deploymentmanager.resources.get",
    "deploymentmanager.resources.list",
  ]
}

# Grant the update-only role
resource "google_project_iam_member" "privesc28_dm_update" {
  count = var.enable_privesc28 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc28_dm_update[0].id
  member  = "serviceAccount:${google_service_account.privesc28_dm_update[0].email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc28_actas" {
  count = var.enable_privesc28 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc28_dm_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc28_impersonate" {
  count = var.enable_privesc28 ? 1 : 0

  service_account_id = google_service_account.privesc28_dm_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# =============================================================================
# TARGET INFRASTRUCTURE: Existing deployment to hijack
# =============================================================================

# Simple target deployment that can be modified via update
# This creates a minimal GCS bucket - attacker will update to add a VM with high-priv SA
resource "google_deployment_manager_deployment" "privesc28_target" {
  count = var.enable_privesc28 ? 1 : 0

  name    = "${var.resource_prefix}28-target"
  project = var.project_id

  target {
    config {
      content = <<-EOF
        resources:
        - name: ${var.resource_prefix}28-placeholder
          type: storage.v1.bucket
          properties:
            name: ${var.project_id}-privesc28-placeholder
            location: US
            storageClass: STANDARD
      EOF
    }
  }

  labels {
    key   = "purpose"
    value = "privesc28-target"
  }
}
