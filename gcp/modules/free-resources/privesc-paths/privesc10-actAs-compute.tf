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
#     - iam.serviceAccounts.actAs (custom role at project level)
#     - compute.instances.create
#   Supporting (Required for exploitation):
#     - compute.disks.create (required to create boot disk)
#     - compute.instances.setServiceAccount (required to attach high-priv SA)
#   SSH Access (handled by project-level SSH user, not this SA):
#     - The attacker uses their own SSH permissions to connect after VM creation

resource "google_service_account" "privesc10_actas_compute" {
  account_id   = "${var.resource_prefix}10-actas-compute"
  display_name = "Privesc10 - actAs + Compute"
  description  = "Can escalate via VM creation with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with only actAs (instead of roles/iam.serviceAccountUser which has 5 permissions)
resource "google_project_iam_custom_role" "privesc10_actas" {
  role_id     = "${var.resource_prefix}_10_actAs"
  title       = "Privesc10 - actAs Only"
  description = "Vulnerable: Can act as any service account in the project"
  project     = var.project_id

  permissions = [
    "iam.serviceAccounts.actAs",
  ]
}

# Grant actAs at project level (visible in IAM console and CloudFox)
resource "google_project_iam_member" "privesc10_actas" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc10_actas.id
  member  = "serviceAccount:${google_service_account.privesc10_actas_compute.email}"
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
    "compute.instances.setServiceAccount",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
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
