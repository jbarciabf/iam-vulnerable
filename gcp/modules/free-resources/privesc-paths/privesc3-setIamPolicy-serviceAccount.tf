# Privesc Path 3: setIamPolicy on Service Account
#
# VULNERABILITY: A service account with iam.serviceAccounts.setIamPolicy on a
# high-privilege service account can grant itself the ability to impersonate it.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Call setIamPolicy on the high-priv SA
#   3. Add a binding granting yourself roles/iam.serviceAccountTokenCreator
#   4. Impersonate the high-priv SA
#
# DETECTION: FoxMapper detects this via the setIamPolicy edge checker
#
# REAL-WORLD IMPACT: Critical - Can gain impersonation rights to any SA

resource "google_service_account" "privesc3_set_sa_iam" {
  account_id   = "${var.resource_prefix}03-set-sa-iam"
  display_name = "Privesc03 - setIamPolicy on SA"
  description  = "Can escalate by modifying SA IAM policy"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Custom role with setIamPolicy permission
resource "google_project_iam_custom_role" "set_sa_iam_policy" {
  role_id     = "${var.resource_prefix}_03_setSAIamPolicy"
  title       = "Privesc03 - Set SA IAM Policy"
  description = "Vulnerable: Can modify IAM policy on any service account in the project"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
  project = var.project_id
}

# Grant setIamPolicy at project level (visible in IAM and CloudFox)
resource "google_project_iam_member" "privesc3_set_sa_iam" {
  project = var.project_id
  role    = google_project_iam_custom_role.set_sa_iam_policy.id
  member  = "serviceAccount:${google_service_account.privesc3_set_sa_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc3_impersonate" {
  service_account_id = google_service_account.privesc3_set_sa_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
