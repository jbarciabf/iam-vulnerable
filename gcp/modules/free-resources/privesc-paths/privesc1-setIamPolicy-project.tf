# Privesc Path 1: setIamPolicy on Project
#
# VULNERABILITY: A service account with resourcemanager.projects.setIamPolicy
# can modify the project's IAM policy to grant itself (or anyone) the Owner role.
#
# EXPLOITATION:
#   1. Impersonate the service account
#   2. Get current project IAM policy
#   3. Add a binding granting yourself roles/owner
#   4. Set the modified policy
#
# DETECTION: FoxMapper detects this via the setIamPolicy edge checker
#
# REAL-WORLD IMPACT: Critical - Full project takeover

resource "google_service_account" "privesc1_set_iam_policy" {
  account_id   = "${var.resource_prefix}1-set-iam-policy"
  display_name = "Privesc1 - setIamPolicy on Project"
  description  = "Can escalate by modifying project IAM policy"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Custom role with the vulnerable permissions
resource "google_project_iam_custom_role" "set_iam_policy" {
  role_id     = "${var.resource_prefix}_01_setIamPolicy"
  title       = "Privesc01 - Set Project IAM Policy"
  description = "Vulnerable: Can read and modify project IAM policy"
  permissions = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
  ]
  project = var.project_id
}

# Assign the vulnerable role to the service account
resource "google_project_iam_member" "privesc1_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.set_iam_policy.id
  member  = "serviceAccount:${google_service_account.privesc1_set_iam_policy.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc1_impersonate" {
  service_account_id = google_service_account.privesc1_set_iam_policy.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
