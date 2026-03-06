# Privesc Path 8: OpenID Token Generation + Workload Identity Federation
#
# VULNERABILITY: A service account with iam.serviceAccounts.getOpenIdToken on a
# high-privilege SA can generate OIDC identity tokens for it. Combined with a
# Workload Identity Federation pool that trusts GCP's OIDC issuer, the attacker
# can exchange the OIDC token for an access token via STS.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Call generateIdToken API for the high-priv SA (audience = WIF provider URL)
#   3. Exchange the OIDC token for a federated access token via STS
#   4. Use the federated token to impersonate the high-priv SA (generateAccessToken)
#
# DETECTION: FoxMapper detects this via the getOpenIdToken edge checker
#
# REAL-WORLD IMPACT: High - OIDC token → federated token → SA access token chain

resource "google_service_account" "privesc8_get_oidc_token" {
  account_id   = "${var.resource_prefix}08-get-oidc-token"
  display_name = "Privesc08 - getOpenIdToken"
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

# Grant OIDC token generation at project level (visible in IAM and CloudFox)
resource "google_project_iam_member" "privesc8_oidc_creator" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc8_oidc_creator.id
  member  = "serviceAccount:${google_service_account.privesc8_get_oidc_token.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc8_impersonate" {
  service_account_id = google_service_account.privesc8_get_oidc_token.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# =============================================================================
# Workload Identity Federation - Enables OIDC → access token exchange
# =============================================================================

# WIF Pool - container for identity providers
resource "google_iam_workload_identity_pool" "privesc8_pool" {
  workload_identity_pool_id = "${var.resource_prefix}-08-oidc-pool"
  display_name              = "Privesc08 OIDC Pool"
  description               = "Accepts GCP OIDC tokens for privesc path 8"
  project                   = var.project_id

  depends_on = [google_project_service.iam, google_project_service.sts]
}

# WIF Provider - trusts GCP's OIDC issuer (accounts.google.com)
resource "google_iam_workload_identity_pool_provider" "privesc8_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.privesc8_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.resource_prefix}-08-gcp-oidc"
  display_name                       = "Privesc08 GCP OIDC Provider"
  description                        = "Trusts OIDC tokens issued by GCP (accounts.google.com)"
  project                            = var.project_id

  # Trust GCP's OIDC issuer
  oidc {
    issuer_uri = "https://accounts.google.com"
  }

  # Map the SA email from the OIDC token's sub claim
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.sa_email"   = "assertion.email"
  }

  # Only accept tokens from SAs in this project
  attribute_condition = "assertion.email.endsWith('@${var.project_id}.iam.gserviceaccount.com')"
}

# Misconfiguration: ANY identity from the WIF pool can impersonate the high-priv SA
# This is a common real-world mistake - overly broad WIF bindings that grant
# workloadIdentityUser to all principals in a pool instead of specific identities.
# The attacker exploits this by generating an OIDC token for ANY SA in the project
# (using getOpenIdToken), exchanging it via STS, and impersonating the high-priv SA.
resource "google_service_account_iam_member" "privesc8_wif_impersonate" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.privesc8_pool.name}/*"
}
