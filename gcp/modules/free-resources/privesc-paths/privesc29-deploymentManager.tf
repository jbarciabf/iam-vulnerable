# Privesc Path 29: Deployment Manager
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

resource "google_service_account" "privesc29_deployment_manager" {
  account_id   = "${var.resource_prefix}17-deployment-mgr"
  display_name = "Privesc17 - Deployment Manager"
  description  = "Can escalate via Deployment Manager"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Grant Deployment Manager editor
resource "google_project_iam_member" "privesc29_deployment" {
  project = var.project_id
  role    = "roles/deploymentmanager.editor"
  member  = "serviceAccount:${google_service_account.privesc29_deployment_manager.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc29_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc29_deployment_manager.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc29_impersonate" {
  service_account_id = google_service_account.privesc29_deployment_manager.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
