# Privesc Path 26: Secret Manager setIamPolicy
#
# VULNERABILITY: A service account with secretmanager.secrets.setIamPolicy
# can grant itself or others access to secrets, potentially exposing
# credentials, API keys, or other sensitive data.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List secrets in the project
#   3. Grant yourself secretmanager.versions.access on sensitive secrets
#   4. Access the secret values
#
# DETECTION: FoxMapper detects this via the secretManagerSetIamPolicy edge checker
#
# REAL-WORLD IMPACT: Critical - Access to all secrets in scope

resource "google_service_account" "privesc26_secret_set_iam" {
  account_id   = "${var.resource_prefix}26-secret-setiam"
  display_name = "Privesc26 - secretmanager.setIamPolicy"
  description  = "Can escalate via secretmanager.secrets.setIamPolicy"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant admin ONLY on the target secret (not project-wide)
# This prevents the attacker from modifying IAM on other secrets
resource "google_secret_manager_secret_iam_member" "privesc26_secret_admin" {
  secret_id = google_secret_manager_secret.target_secret.id
  role      = "roles/secretmanager.admin"
  member    = "serviceAccount:${google_service_account.privesc26_secret_set_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc26_impersonate" {
  service_account_id = google_service_account.privesc26_secret_set_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
