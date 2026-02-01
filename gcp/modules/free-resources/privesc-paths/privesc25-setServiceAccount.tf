# Privesc Path 25: Set Service Account on Compute Instance
#
# VULNERABILITY: A user with compute.instances.setServiceAccount can change
# the service account attached to an existing VM to a high-privilege SA.
#
# EXPLOITATION:
#   1. Find a VM with weak access or that attacker controls
#   2. Use setServiceAccount to attach high-privilege SA
#   3. SSH to the VM or use metadata server
#   4. Access the high-privilege SA's token from metadata
#
# DETECTION: FoxMapper detects this via the setServiceAccount edge checker
#
# REAL-WORLD IMPACT: Critical - SA hijacking on existing VMs

resource "google_service_account" "privesc25_set_sa" {
  account_id   = "${var.resource_prefix}25-set-sa"
  display_name = "Privesc25 - setServiceAccount"
  description  = "Can escalate via compute.instances.setServiceAccount"
  project      = var.project_id
}

# Create a custom role with setServiceAccount permission
resource "google_project_iam_custom_role" "privesc25_set_sa" {
  role_id     = "${var.resource_prefix}_25_set_sa"
  title       = "Privesc25 Set Service Account"
  description = "Can set service account on compute instances"
  project     = var.project_id

  permissions = [
    "compute.instances.setServiceAccount",
    "compute.instances.get",
    "compute.instances.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc25_set_sa" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc25_set_sa.id
  member  = "serviceAccount:${google_service_account.privesc25_set_sa.email}"
}

# Grant actAs on the high-privilege SA (required to attach it)
resource "google_service_account_iam_member" "privesc25_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc25_set_sa.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc25_impersonate" {
  service_account_id = google_service_account.privesc25_set_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
