# Privesc Path 23: Implicit Delegation
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

resource "google_service_account" "privesc23_implicit_delegation" {
  account_id   = "${var.resource_prefix}23-implicit-deleg"
  display_name = "Privesc23 - Implicit Delegation"
  description  = "Can escalate via implicit delegation chain"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant implicit delegation on the medium-priv SA
# This allows using medium-priv's permissions to impersonate further
resource "google_service_account_iam_member" "privesc23_implicit_delegation" {
  service_account_id = google_service_account.medium_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.privesc23_implicit_delegation.email}"
}

# Medium-priv SA already has impersonation on high-priv (defined elsewhere)
# We need to ensure that chain exists - grant token creator from medium to high
resource "google_service_account_iam_member" "privesc23_chain" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.medium_priv.email}"
}

# Allow the attacker to impersonate the vulnerable service account
resource "google_service_account_iam_member" "privesc23_impersonate" {
  service_account_id = google_service_account.privesc23_implicit_delegation.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
