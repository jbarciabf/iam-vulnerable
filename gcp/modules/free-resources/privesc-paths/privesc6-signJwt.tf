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
  account_id   = "${var.resource_prefix}6-sign-jwt"
  display_name = "Privesc6 - signJwt"
  description  = "Can escalate via JWT signing"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Custom role for list/get at project level (discovery only)
resource "google_project_iam_custom_role" "privesc6_sa_viewer" {
  role_id     = "${var.resource_prefix}_6_saViewer"
  title       = "Privesc6 - SA Viewer"
  description = "Can list and view service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
  project = var.project_id
}

# Grant viewer at project level
resource "google_project_iam_member" "privesc6_viewer" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc6_sa_viewer.id
  member  = "serviceAccount:${google_service_account.privesc6_sign_jwt.email}"
}

# Custom role with signJwt permission - granted at SA level only
resource "google_project_iam_custom_role" "sign_jwt" {
  role_id     = "${var.resource_prefix}_signJwt"
  title       = "Privesc6 - Sign JWT"
  description = "Vulnerable: Can sign JWTs as this specific service account"
  permissions = [
    "iam.serviceAccounts.signJwt",
  ]
  project = var.project_id
}

# Grant signJwt ONLY on the high-privilege SA (not project-wide)
resource "google_service_account_iam_member" "privesc6_sign_jwt_on_high_priv" {
  service_account_id = google_service_account.high_priv.name
  role               = google_project_iam_custom_role.sign_jwt.id
  member             = "serviceAccount:${google_service_account.privesc6_sign_jwt.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc6_impersonate" {
  service_account_id = google_service_account.privesc6_sign_jwt.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
