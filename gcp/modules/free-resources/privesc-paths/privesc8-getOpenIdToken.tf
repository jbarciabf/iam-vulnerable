# Privesc Path 8: OpenID Token Generation
#
# VULNERABILITY: A service account with iam.serviceAccounts.getOpenIdToken
# can generate OIDC identity tokens for the target SA. These tokens can be
# used for authentication to services that accept OIDC tokens.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Call generateIdToken API for the high-priv SA
#   3. Receive an OIDC token
#   4. Use the token to authenticate to Cloud Run, Cloud Functions, etc.
#
# DETECTION: FoxMapper detects this via the getOpenIdToken edge checker
#
# REAL-WORLD IMPACT: High - Can access OIDC-protected services

resource "google_service_account" "privesc8_get_oidc_token" {
  account_id   = "${var.resource_prefix}8-get-oidc-token"
  display_name = "Privesc8 - getOpenIdToken"
  description  = "Can escalate via OIDC token generation"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Create a custom role with just getOpenIdToken
resource "google_project_iam_custom_role" "privesc8_oidc_creator" {
  role_id     = "${var.resource_prefix}_08_oidc_creator"
  title       = "Privesc08 OIDC Token Creator"
  description = "Can generate OIDC tokens for service accounts"
  project     = var.project_id

  permissions = [
    "iam.serviceAccounts.getOpenIdToken",
  ]
}

# Grant OIDC token generation on the high-privilege service account
resource "google_service_account_iam_member" "privesc8_oidc_creator" {
  service_account_id = google_service_account.high_priv.name
  role               = google_project_iam_custom_role.privesc8_oidc_creator.id
  member             = "serviceAccount:${google_service_account.privesc8_get_oidc_token.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc8_impersonate" {
  service_account_id = google_service_account.privesc8_get_oidc_token.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
