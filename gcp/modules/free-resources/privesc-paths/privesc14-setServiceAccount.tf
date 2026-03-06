# Privesc Path 14: Set Service Account on Compute Instance
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
#
# DISABLED BY DEFAULT: Requires enable_privesc14 = true (creates target VM ~$6-7/mo)

resource "google_service_account" "privesc14_set_sa" {
  count = var.enable_privesc14 ? 1 : 0

  account_id   = "${var.resource_prefix}14-set-sa"
  display_name = "Privesc14 - setServiceAccount"
  description  = "Can escalate via compute.instances.setServiceAccount"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Create a custom role with setServiceAccount permission
resource "google_project_iam_custom_role" "privesc14_set_sa" {
  count = var.enable_privesc14 ? 1 : 0

  role_id     = "${var.resource_prefix}_14_set_sa"
  title       = "Privesc14 Set Service Account"
  description = "Can set service account on compute instances"
  project     = var.project_id

  permissions = [
    "compute.instances.setServiceAccount",
    "compute.instances.get",
    "compute.instances.stop",   # Required: instance must be stopped to change SA
    "compute.instances.start",  # Required: instance must be started after changing SA
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc14_set_sa" {
  count = var.enable_privesc14 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc14_set_sa[0].id
  member  = "serviceAccount:${google_service_account.privesc14_set_sa[0].email}"
}

# Custom role with only actAs (instead of roles/iam.serviceAccountUser)
resource "google_project_iam_custom_role" "privesc14_actas" {
  count = var.enable_privesc14 ? 1 : 0

  role_id     = "${var.resource_prefix}_14_actAs"
  title       = "Privesc14 - actAs Only"
  description = "Required to attach a service account to a compute instance"
  project     = var.project_id

  permissions = [
    "iam.serviceAccounts.actAs",
  ]
}

resource "google_project_iam_member" "privesc14_actas" {
  count = var.enable_privesc14 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc14_actas[0].id
  member  = "serviceAccount:${google_service_account.privesc14_set_sa[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc14_impersonate" {
  count = var.enable_privesc14 ? 1 : 0

  service_account_id = google_service_account.privesc14_set_sa[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
