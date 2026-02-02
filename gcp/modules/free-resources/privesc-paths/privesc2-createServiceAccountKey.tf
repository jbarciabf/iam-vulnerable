# Privesc Path 2: Create Service Account Key
#
# VULNERABILITY: A service account with iam.serviceAccountKeys.create on a
# high-privilege service account can create a key for that SA and use it directly.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a new key for the high-privilege SA
#   3. Download and use the key to authenticate as the high-priv SA
#
# DETECTION: FoxMapper detects this via the createKey edge checker
#
# REAL-WORLD IMPACT: Critical - Direct credential theft for privileged SA

resource "google_service_account" "privesc2_create_key" {
  account_id   = "${var.resource_prefix}2-create-sa-key"
  display_name = "Privesc2 - Create SA Key"
  description  = "Can escalate by creating keys for high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Custom role with only list/get permissions at project level
resource "google_project_iam_custom_role" "privesc2_sa_viewer" {
  role_id     = "${var.resource_prefix}_2_saViewer"
  title       = "Privesc2 - SA Viewer"
  description = "Can list and view service accounts"
  permissions = [
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.get",
  ]
  project = var.project_id
}

# Grant list/get at project level (needed for discovery)
resource "google_project_iam_member" "privesc2_viewer" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc2_sa_viewer.id
  member  = "serviceAccount:${google_service_account.privesc2_create_key.email}"
}

# Custom role with createKey permission - granted at SA level only
resource "google_project_iam_custom_role" "create_sa_key" {
  role_id     = "${var.resource_prefix}_createSAKey"
  title       = "Privesc2 - Create Service Account Key"
  description = "Vulnerable: Can create keys for this specific service account"
  permissions = [
    "iam.serviceAccountKeys.create",
  ]
  project = var.project_id
}

# Grant createKey ONLY on the high-privilege SA (not project-wide)
resource "google_service_account_iam_member" "privesc2_create_key_on_high_priv" {
  service_account_id = google_service_account.high_priv.name
  role               = google_project_iam_custom_role.create_sa_key.id
  member             = "serviceAccount:${google_service_account.privesc2_create_key.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc2_impersonate" {
  service_account_id = google_service_account.privesc2_create_key.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
