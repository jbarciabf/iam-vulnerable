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
  account_id   = "${var.resource_prefix}3-set-sa-iam"
  display_name = "Privesc3 - setIamPolicy on SA"
  description  = "Can escalate by modifying SA IAM policy"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Custom role for list/get at project level (discovery only)
resource "google_project_iam_custom_role" "privesc3_sa_viewer" {
  role_id     = "${var.resource_prefix}_3_saViewer"
  title       = "Privesc3 - SA Viewer"
  description = "Can list and view service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
  project = var.project_id
}

# Grant viewer at project level
resource "google_project_iam_member" "privesc3_viewer" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc3_sa_viewer.id
  member  = "serviceAccount:${google_service_account.privesc3_set_sa_iam.email}"
}

# Custom role with setIamPolicy permission - granted at SA level only
resource "google_project_iam_custom_role" "set_sa_iam_policy" {
  role_id     = "${var.resource_prefix}_setSAIamPolicy"
  title       = "Privesc3 - Set SA IAM Policy"
  description = "Vulnerable: Can modify IAM policy on this specific service account"
  permissions = [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
  project = var.project_id
}

# Grant setIamPolicy ONLY on the high-privilege SA (not project-wide)
resource "google_service_account_iam_member" "privesc3_set_iam_on_high_priv" {
  service_account_id = google_service_account.high_priv.name
  role               = google_project_iam_custom_role.set_sa_iam_policy.id
  member             = "serviceAccount:${google_service_account.privesc3_set_sa_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc3_impersonate" {
  service_account_id = google_service_account.privesc3_set_sa_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
