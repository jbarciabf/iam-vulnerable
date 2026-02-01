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
  account_id   = "${var.resource_prefix}10-sign-jwt"
  display_name = "Privesc10 - signJwt"
  description  = "Can escalate via JWT signing"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Custom role with signJwt permission
resource "google_project_iam_custom_role" "sign_jwt" {
  role_id     = "${var.resource_prefix}_signJwt"
  title       = "Privesc - Sign JWT"
  description = "Vulnerable: Can sign JWTs as service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.signJwt",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc6_role" {
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
