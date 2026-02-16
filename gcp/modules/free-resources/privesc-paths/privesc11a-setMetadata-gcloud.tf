# Privesc Path 11a: Set Instance Metadata via gcloud compute ssh
#
# VULNERABILITY: A service account with compute.instances.setMetadata can use
# gcloud compute ssh which automatically creates and injects SSH keys.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find instances with high-priv service accounts attached
#   3. Use `gcloud compute ssh` (it auto-creates ~/.ssh/google_compute_engine key
#      and injects it into instance metadata)
#   4. Access the metadata server to get tokens for the attached SA
#
# DETECTION: FoxMapper detects this via the setMetadata edge checker
#
# REAL-WORLD IMPACT: Critical - SSH access to compute instances
#
# DISABLED BY DEFAULT: Requires enable_privesc11a = true (creates target VM ~$2-5/mo)

resource "google_service_account" "privesc11a_set_metadata" {
  count = var.enable_privesc11a ? 1 : 0

  account_id   = "${var.resource_prefix}11a-set-metadata"
  display_name = "Privesc11a - setMetadata (gcloud ssh)"
  description  = "Can escalate via gcloud compute ssh auto-key injection"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with setMetadata permission
resource "google_project_iam_custom_role" "privesc11a_set_metadata" {
  count = var.enable_privesc11a ? 1 : 0

  role_id     = "${var.resource_prefix}_11a_setMetadata"
  title       = "Privesc11a - Set Instance Metadata (gcloud)"
  description = "Vulnerable: Can modify instance metadata via gcloud compute ssh"
  permissions = [
    "compute.instances.list",
    "compute.instances.get",
    "compute.instances.setMetadata",
    "compute.projects.get",
    "compute.zones.list",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc11a_role" {
  count = var.enable_privesc11a ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc11a_set_metadata[0].id
  member  = "serviceAccount:${google_service_account.privesc11a_set_metadata[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc11a_impersonate" {
  count = var.enable_privesc11a ? 1 : 0

  service_account_id = google_service_account.privesc11a_set_metadata[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on high-priv SA (required for gcloud compute ssh to modify instance metadata)
resource "google_service_account_iam_member" "privesc11a_actas_high_priv" {
  count = var.enable_privesc11a ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc11a_set_metadata[0].email}"
}
