# Privesc Path 27: Deployment Manager
#
# VULNERABILITY: A service account with deploymentmanager.deployments.create and
# actAs can deploy resources that run with a high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Deployment Manager deployment
#   3. The deployment creates resources (e.g., GCE, Cloud Functions)
#      with the high-priv SA attached
#   4. Access the deployed resources to get high-priv SA credentials
#
# DETECTION: FoxMapper detects this via the deploymentManager edge checker
#
# REAL-WORLD IMPACT: High - Infrastructure-as-code abuse
#
# NOTE: Deployment Manager is deprecated in favor of Terraform/Config Connector
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - deploymentmanager.deployments.create
#   Supporting (Required for exploitation):
#     - deploymentmanager.deployments.get (to check deployment status)
#     - deploymentmanager.operations.get (to monitor deployment)
#     - deploymentmanager.manifests.get (to view deployment details)

resource "google_service_account" "privesc27_deployment_manager" {
  account_id   = "${var.resource_prefix}27-deployment-manager"
  display_name = "Privesc27 - Deployment Manager"
  description  = "Can escalate via Deployment Manager"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with minimal Deployment Manager permissions
resource "google_project_iam_custom_role" "privesc27_deployment" {
  role_id     = "${var.resource_prefix}_27_deploymentmanager"
  title       = "Privesc27 - Deployment Manager Deploy"
  description = "Minimal permissions for Deployment Manager with SA"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "deploymentmanager.deployments.create",
    # Supporting permissions (required for exploitation)
    "deploymentmanager.deployments.get",
    "deploymentmanager.deployments.list",
    "deploymentmanager.deployments.update",
    "deploymentmanager.operations.get",
    "deploymentmanager.operations.list",
    "deploymentmanager.manifests.get",
    "deploymentmanager.manifests.list",
    "deploymentmanager.resources.get",
    "deploymentmanager.resources.list",
    # Utility permissions
    "deploymentmanager.deployments.delete",
  ]
}

# Grant Deployment Manager permissions
resource "google_project_iam_member" "privesc27_deployment" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc27_deployment.id
  member  = "serviceAccount:${google_service_account.privesc27_deployment_manager.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc27_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc27_deployment_manager.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc27_impersonate" {
  service_account_id = google_service_account.privesc27_deployment_manager.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
