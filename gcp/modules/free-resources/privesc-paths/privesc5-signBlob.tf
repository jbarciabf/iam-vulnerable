# Privesc Path 5: Sign Blob
#
# VULNERABILITY: A service account with iam.serviceAccounts.signBlob on a
# high-privilege SA can sign arbitrary data, enabling token forgery.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Craft a JWT payload with desired claims
#   3. Use signBlob to sign the JWT as the high-priv SA
#   4. Exchange the signed JWT for an access token
#
# DETECTION: FoxMapper detects this via the signBlob edge checker
#
# REAL-WORLD IMPACT: High - Can forge authentication tokens

resource "google_service_account" "privesc5_sign_blob" {
  account_id   = "${var.resource_prefix}5-sign-blob"
  display_name = "Privesc5 - signBlob"
  description  = "Can escalate via blob signing"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Custom role for list/get at project level (discovery only)
resource "google_project_iam_custom_role" "privesc5_sa_viewer" {
  role_id     = "${var.resource_prefix}_5_saViewer"
  title       = "Privesc5 - SA Viewer"
  description = "Can list and view service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
  project = var.project_id
}

# Grant viewer at project level
resource "google_project_iam_member" "privesc5_viewer" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc5_sa_viewer.id
  member  = "serviceAccount:${google_service_account.privesc5_sign_blob.email}"
}

# Custom role with signBlob permission - granted at SA level only
resource "google_project_iam_custom_role" "sign_blob" {
  role_id     = "${var.resource_prefix}_signBlob"
  title       = "Privesc5 - Sign Blob"
  description = "Vulnerable: Can sign data as this specific service account"
  permissions = [
    "iam.serviceAccounts.signBlob",
  ]
  project = var.project_id
}

# Grant signBlob ONLY on the high-privilege SA (not project-wide)
resource "google_service_account_iam_member" "privesc5_sign_blob_on_high_priv" {
  service_account_id = google_service_account.high_priv.name
  role               = google_project_iam_custom_role.sign_blob.id
  member             = "serviceAccount:${google_service_account.privesc5_sign_blob.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc5_impersonate" {
  service_account_id = google_service_account.privesc5_sign_blob.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
