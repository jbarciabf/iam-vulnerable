# Privesc Path 12: OS Login
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
#
# DISABLED BY DEFAULT: Requires enable_privesc12 = true (creates target VM ~$2-5/mo)

resource "google_service_account" "privesc12_os_login" {
  count = var.enable_privesc12 ? 1 : 0

  account_id   = "${var.resource_prefix}12-os-login"
  display_name = "Privesc12 - OS Login"
  description  = "Can escalate via OS Login SSH access"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Grant OS Login permissions
resource "google_project_iam_member" "privesc12_os_login" {
  count = var.enable_privesc12 ? 1 : 0

  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.privesc12_os_login[0].email}"
}

# Also need to be able to list/get instances
resource "google_project_iam_member" "privesc12_compute_viewer" {
  count = var.enable_privesc12 ? 1 : 0

  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.privesc12_os_login[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc12_impersonate" {
  count = var.enable_privesc12 ? 1 : 0

  service_account_id = google_service_account.privesc12_os_login[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
