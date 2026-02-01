# Privesc Path 4: Direct Impersonation via getAccessToken
#
# VULNERABILITY: A service account with iam.serviceAccounts.getAccessToken on a
# high-privilege SA can directly generate access tokens for it.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Call generateAccessToken API for the high-priv SA
#   3. Receive an access token valid for 1 hour
#   4. Use the token to make API calls as the high-priv SA
#
# DETECTION: FoxMapper detects this via the getAccessToken edge checker
#
# REAL-WORLD IMPACT: Critical - Direct token generation

resource "google_service_account" "privesc4_get_access_token" {
  account_id   = "${var.resource_prefix}8-get-access-token"
  display_name = "Privesc8 - getAccessToken"
  description  = "Can escalate via direct token generation"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Grant token creator on the high-privilege service account
# This is the same as actAs but more direct
resource "google_service_account_iam_member" "privesc4_token_creator" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.privesc4_get_access_token.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc4_impersonate" {
  service_account_id = google_service_account.privesc4_get_access_token.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
