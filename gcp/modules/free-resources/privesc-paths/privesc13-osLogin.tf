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
#
# DISABLED BY DEFAULT: Requires enable_privesc13 = true (creates target VM ~$6-7/mo)

resource "google_service_account" "privesc13_os_login" {
  count = var.enable_privesc13 ? 1 : 0

  account_id   = "${var.resource_prefix}13-os-login"
  display_name = "Privesc13 - OS Login"
  description  = "Can escalate via OS Login SSH access"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# OS Login requires the predefined role - custom roles with the same permissions
# don't work because the OS Login PAM module checks for the predefined role name
resource "google_project_iam_member" "privesc13_os_login" {
  count = var.enable_privesc13 ? 1 : 0

  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${google_service_account.privesc13_os_login[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc13_impersonate" {
  count = var.enable_privesc13 ? 1 : 0

  service_account_id = google_service_account.privesc13_os_login[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on high-priv SA (required for OS Login to the VM)
# Note: Using roles/iam.serviceAccountUser because OS Login PAM module
# doesn't evaluate IAM conditions on custom roles for actAs checks.
# This adds get/list permissions on the SA, but is required for SSH to work.
resource "google_service_account_iam_member" "privesc13_actas_high_priv" {
  count = var.enable_privesc13 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc13_os_login[0].email}"
}
