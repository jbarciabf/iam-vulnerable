# Privesc Path 9: Sign Blob
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

resource "google_service_account" "privesc9_sign_blob" {
  account_id   = "${var.resource_prefix}9-sign-blob"
  display_name = "Privesc9 - signBlob"
  description  = "Can escalate via blob signing"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Custom role with signBlob permission
resource "google_project_iam_custom_role" "sign_blob" {
  role_id     = "${var.resource_prefix}_signBlob"
  title       = "Privesc - Sign Blob"
  description = "Vulnerable: Can sign data as service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.signBlob",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc9_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.sign_blob.id
  member  = "serviceAccount:${google_service_account.privesc9_sign_blob.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc9_impersonate" {
  service_account_id = google_service_account.privesc9_sign_blob.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
