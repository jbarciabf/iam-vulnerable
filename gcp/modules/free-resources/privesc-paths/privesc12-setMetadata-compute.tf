# Privesc Path 12: Set Instance Metadata (SSH Keys)
#
# VULNERABILITY: A service account with compute.instances.setMetadata can add
# SSH keys to instances, enabling SSH access and metadata credential theft.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find instances with high-priv service accounts attached
#   3. Add your SSH public key to the instance metadata
#   4. SSH into the instance
#   5. Access the metadata server to get tokens for the attached SA
#
# DETECTION: FoxMapper detects this via the setMetadata edge checker
#
# REAL-WORLD IMPACT: Critical - SSH access to compute instances

resource "google_service_account" "privesc12_set_metadata" {
  account_id   = "${var.resource_prefix}12-set-metadata"
  display_name = "Privesc12 - setMetadata"
  description  = "Can escalate via compute metadata modification"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with setMetadata permission
resource "google_project_iam_custom_role" "set_metadata" {
  role_id     = "${var.resource_prefix}_setMetadata"
  title       = "Privesc - Set Instance Metadata"
  description = "Vulnerable: Can modify instance metadata including SSH keys"
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
resource "google_project_iam_member" "privesc12_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.set_metadata.id
  member  = "serviceAccount:${google_service_account.privesc12_set_metadata.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc12_impersonate" {
  service_account_id = google_service_account.privesc12_set_metadata.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
