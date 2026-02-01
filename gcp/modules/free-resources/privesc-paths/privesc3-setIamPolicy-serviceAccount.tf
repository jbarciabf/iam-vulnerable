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
}

# Custom role with the vulnerable permission
resource "google_project_iam_custom_role" "set_sa_iam_policy" {
  role_id     = "${var.resource_prefix}_setSAIamPolicy"
  title       = "Privesc - Set SA IAM Policy"
  description = "Vulnerable: Can modify IAM policy on service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc3_role" {
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
