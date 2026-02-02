# Privesc Path 25: Secret Manager Access
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

resource "google_service_account" "privesc25_secret_access" {
  account_id   = "${var.resource_prefix}25-secret-access"
  display_name = "Privesc25 - Secret Manager"
  description  = "Can access secrets in Secret Manager"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant secret accessor ONLY on the target secret (not project-wide)
# This prevents the attacker from accessing other secrets
resource "google_secret_manager_secret_iam_member" "privesc25_secret_accessor" {
  secret_id = google_secret_manager_secret.target_secret.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.privesc25_secret_access.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc25_impersonate" {
  service_account_id = google_service_account.privesc25_secret_access.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
