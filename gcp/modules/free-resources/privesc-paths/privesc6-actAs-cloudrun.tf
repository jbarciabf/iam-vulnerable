# Privesc Path 6: actAs + Cloud Run Deployment
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus run.services.create can deploy a Cloud Run service as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Deploy a Cloud Run service with the high-priv SA
#   3. The container can access GCP APIs as the high-priv SA
#   4. Send requests to the service to execute privileged operations
#
# DETECTION: FoxMapper detects this via the actAs + run edge checker
#
# REAL-WORLD IMPACT: Critical - Container-based privilege escalation

resource "google_service_account" "privesc6_actas_cloudrun" {
  account_id   = "${var.resource_prefix}6-actas-cloudrun"
  display_name = "Privesc6 - actAs + Cloud Run"
  description  = "Can escalate via Cloud Run with high-priv SA"
  project      = var.project_id
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc6_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc6_actas_cloudrun.email}"
}

# Grant Cloud Run developer permissions
resource "google_project_iam_member" "privesc6_run" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.privesc6_actas_cloudrun.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc6_impersonate" {
  service_account_id = google_service_account.privesc6_actas_cloudrun.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
