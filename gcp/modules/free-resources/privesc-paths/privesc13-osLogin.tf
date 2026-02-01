# Privesc Path 13: OS Login
#
# VULNERABILITY: A service account with compute.instances.osLogin or
# compute.instances.osAdminLogin can SSH to instances using OS Login.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find instances with OS Login enabled and high-priv SAs
#   3. Use gcloud compute ssh with OS Login
#   4. Access the metadata server for the instance's SA credentials
#
# DETECTION: FoxMapper detects this via the osLogin edge checker
#
# REAL-WORLD IMPACT: High - OS Login bypass for SSH access

resource "google_service_account" "privesc13_os_login" {
  account_id   = "${var.resource_prefix}13-os-login"
  display_name = "Privesc13 - OS Login"
  description  = "Can escalate via OS Login SSH access"
  project      = var.project_id
}

# Grant OS Login permissions
resource "google_project_iam_member" "privesc13_os_login" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.privesc13_os_login.email}"
}

# Also need to be able to list/get instances
resource "google_project_iam_member" "privesc13_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.privesc13_os_login.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc13_impersonate" {
  service_account_id = google_service_account.privesc13_os_login.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
