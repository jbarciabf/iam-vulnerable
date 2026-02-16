# Privesc Path 10: actAs + Compute Instance Creation
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus compute.instances.create can create a VM running as the high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Compute Engine instance with the high-priv SA attached
#   3. SSH into the instance
#   4. Use the metadata server to get tokens for the high-priv SA
#
# DETECTION: FoxMapper detects this via the actAs + compute edge checker
#
# REAL-WORLD IMPACT: Critical - Common escalation path in GCP
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - compute.instances.create
#   Supporting (Required for exploitation):
#     - compute.disks.create (required to create boot disk)
#     - compute.subnetworks.use (required to attach to network)
#     - compute.subnetworks.useExternalIp (required for external IP / SSH access)
#     - compute.instances.setMetadata (required for SSH key injection)

resource "google_service_account" "privesc10_actas_compute" {
  account_id   = "${var.resource_prefix}10-actas-compute"
  display_name = "Privesc10 - actAs + Compute"
  description  = "Can escalate via VM creation with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc10_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc10_actas_compute.email}"
}

# Custom role with minimal permissions for compute instance creation
resource "google_project_iam_custom_role" "privesc10_compute" {
  role_id     = "${var.resource_prefix}_10_compute"
  title       = "Privesc10 - Compute Instance Create"
  description = "Minimal permissions for compute instance creation with SA"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "compute.instances.create",
    # Supporting permissions (required for exploitation)
    "compute.disks.create",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    # Utility permissions
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.delete",
    "compute.zones.list",
  ]
}

# Grant compute instance creation permissions
resource "google_project_iam_member" "privesc10_compute" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc10_compute.id
  member  = "serviceAccount:${google_service_account.privesc10_actas_compute.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc10_impersonate" {
  service_account_id = google_service_account.privesc10_actas_compute.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
