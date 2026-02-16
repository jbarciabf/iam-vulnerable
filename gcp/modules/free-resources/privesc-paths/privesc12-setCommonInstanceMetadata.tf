# Privesc Path 12: Set Project-Level Metadata (SSH Keys)
#
# VULNERABILITY: A service account with compute.projects.setCommonInstanceMetadata
# can add SSH keys at the project level, granting SSH access to ALL instances.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Add your SSH public key to project-level metadata
#   3. SSH into ANY instance in the project
#   4. Access the metadata server to get tokens for the attached SA
#
# DETECTION: FoxMapper should detect this via project metadata permissions
#
# REAL-WORLD IMPACT: Critical - SSH access to ALL compute instances in project
#
# DISABLED BY DEFAULT: Requires enable_privesc12 = true (creates target VM ~$2-5/mo)

resource "google_service_account" "privesc12_set_common_metadata" {
  count = var.enable_privesc12 ? 1 : 0

  account_id   = "${var.resource_prefix}12-set-proj-meta"
  display_name = "Privesc12 - setCommonInstanceMetadata"
  description  = "Can escalate via project-level metadata modification"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with setCommonInstanceMetadata permission
resource "google_project_iam_custom_role" "privesc12_set_common_metadata" {
  count = var.enable_privesc12 ? 1 : 0

  role_id     = "${var.resource_prefix}_12_setCommonInstanceMetadata"
  title       = "Privesc12 - Set Project Metadata"
  description = "Vulnerable: Can modify project-level metadata including SSH keys for ALL instances"
  permissions = [
    "compute.projects.get",
    "compute.projects.setCommonInstanceMetadata",
    # Supporting permissions to find VMs with high-priv SAs
    "compute.instances.list",
    "compute.instances.get",
    "compute.zones.list",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc12_role" {
  count = var.enable_privesc12 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc12_set_common_metadata[0].id
  member  = "serviceAccount:${google_service_account.privesc12_set_common_metadata[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc12_impersonate" {
  count = var.enable_privesc12 ? 1 : 0

  service_account_id = google_service_account.privesc12_set_common_metadata[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs at project level (required for modifying project-level metadata)
# This is more powerful than instance-level actAs since it affects ALL SAs
resource "google_project_iam_member" "privesc12_actas_project" {
  count = var.enable_privesc12 ? 1 : 0

  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.privesc12_set_common_metadata[0].email}"
}
