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

# Create a custom role with Secret Manager IAM permissions
resource "google_project_iam_custom_role" "privesc26_secret_set_iam" {
  role_id     = "${var.resource_prefix}_26_secret_set_iam"
  title       = "Privesc26 Secret Manager IAM Admin"
  description = "Can modify IAM policies on secrets"
  project     = var.project_id

  permissions = [
    "secretmanager.secrets.setIamPolicy",
    "secretmanager.secrets.getIamPolicy",
    "secretmanager.secrets.get",
    "secretmanager.secrets.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc26_secret_set_iam" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc26_secret_set_iam.id
  member  = "serviceAccount:${google_service_account.privesc26_secret_set_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc26_impersonate" {
  service_account_id = google_service_account.privesc26_secret_set_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
