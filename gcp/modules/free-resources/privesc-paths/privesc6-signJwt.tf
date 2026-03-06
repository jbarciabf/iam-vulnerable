# Privesc Path 6: Sign JWT
#
# VULNERABILITY: A service account with iam.serviceAccounts.signJwt on a
# high-privilege SA can sign JWTs as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a JWT claiming to be the high-priv SA
#   3. Use signJwt to sign the JWT
#   4. Exchange the signed JWT for an access token
#
# DETECTION: FoxMapper detects this via the signJwt edge checker
#
# REAL-WORLD IMPACT: High - Direct JWT signing for token forgery

resource "google_service_account" "privesc6_sign_jwt" {
  account_id   = "${var.resource_prefix}06-sign-jwt"
  display_name = "Privesc06 - signJwt"
  description  = "Can escalate via JWT signing"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Custom role with signJwt permission
resource "google_project_iam_custom_role" "sign_jwt" {
  role_id     = "${var.resource_prefix}_06_signJwt"
  title       = "Privesc06 - Sign JWT"
  description = "Vulnerable: Can sign JWTs as any service account in the project"
  permissions = [
    "iam.serviceAccounts.signJwt",
  ]
  project = var.project_id
}

# Grant signJwt at project level (visible in IAM and CloudFox)
resource "google_project_iam_member" "privesc6_sign_jwt" {
  project = var.project_id
  role    = google_project_iam_custom_role.sign_jwt.id
  member  = "serviceAccount:${google_service_account.privesc6_sign_jwt.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc6_impersonate" {
  service_account_id = google_service_account.privesc6_sign_jwt.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
