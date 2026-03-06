# Privesc Path 7: Implicit Delegation
#
# VULNERABILITY: A service account with iam.serviceAccounts.implicitDelegation
# on SA-A can use SA-A's permissions to impersonate SA-B if SA-A can impersonate SA-B.
#
# EXPLOITATION:
#   1. Attacker has implicitDelegation on SA-A (medium-priv)
#   2. SA-A has getAccessToken on SA-B (high-priv)
#   3. Attacker can request token for SA-B via delegation chain
#
# DETECTION: FoxMapper detects this via the implicitDelegation edge checker
#
# REAL-WORLD IMPACT: Critical - Multi-hop impersonation chain

resource "google_service_account" "privesc7_implicit_delegation" {
  account_id   = "${var.resource_prefix}07-implicit-deleg"
  display_name = "Privesc07 - Implicit Delegation"
  description  = "Can escalate via implicit delegation chain"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Custom role with only implicitDelegation permission
resource "google_project_iam_custom_role" "privesc7_implicit_delegation" {
  role_id     = "${var.resource_prefix}_07_implicitDelegation"
  title       = "Privesc07 - Implicit Delegation"
  description = "Vulnerable: Can use implicit delegation on any service account in the project"
  permissions = [
    "iam.serviceAccounts.implicitDelegation",
  ]
  project = var.project_id
}

# Grant implicitDelegation at project level (visible in IAM and CloudFox)
resource "google_project_iam_member" "privesc7_implicit_delegation" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc7_implicit_delegation.id
  member  = "serviceAccount:${google_service_account.privesc7_implicit_delegation.email}"
}

# Medium-priv SA has impersonation on high-priv - creates the delegation chain
resource "google_service_account_iam_member" "privesc7_chain" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.medium_priv.email}"
}

# Allow the attacker to impersonate the vulnerable service account
resource "google_service_account_iam_member" "privesc7_impersonate" {
  service_account_id = google_service_account.privesc7_implicit_delegation.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
