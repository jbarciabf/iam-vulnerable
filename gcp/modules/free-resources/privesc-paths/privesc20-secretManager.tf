# Privesc Path 20: Secret Manager Access
#
# VULNERABILITY: A service account with secretmanager.versions.access on secrets
# containing credentials can access those credentials directly.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List secrets in the project
#   3. Access secret versions to retrieve credentials
#   4. Use the retrieved credentials (API keys, passwords, etc.)
#
# DETECTION: FoxMapper detects this via secret access patterns
#
# REAL-WORLD IMPACT: Critical - Direct credential theft

resource "google_service_account" "privesc20_secret_access" {
  account_id   = "${var.resource_prefix}20-secret-access"
  display_name = "Privesc20 - Secret Manager"
  description  = "Can access secrets in Secret Manager"
  project      = var.project_id
}

# Grant Secret Manager accessor
resource "google_project_iam_member" "privesc20_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.privesc20_secret_access.email}"
}

# Also grant ability to list secrets
resource "google_project_iam_member" "privesc20_secrets_viewer" {
  project = var.project_id
  role    = "roles/secretmanager.viewer"
  member  = "serviceAccount:${google_service_account.privesc20_secret_access.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc20_impersonate" {
  service_account_id = google_service_account.privesc20_secret_access.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
