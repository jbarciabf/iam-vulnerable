# Privesc Path 13: Existing SSH Access to High-Priv VM
#
# VULNERABILITY: An attacker whose SSH key is already in project or instance
# metadata can SSH to any VM and steal service account credentials from the
# metadata server.
#
# SCENARIO: Your SSH key was added to project-level metadata by an admin,
# giving you SSH access to all instances. You discover a VM running with
# a high-privilege service account.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account (which has minimal permissions)
#   2. List instances to find ones with high-priv service accounts
#   3. SSH to the instance (your key is already authorized)
#   4. Access the metadata server to get tokens for the attached SA
#
# DETECTION: Hard to detect - attacker is using legitimate SSH access
#
# REAL-WORLD IMPACT: Critical - Legitimate access leads to privilege escalation
#
# DISABLED BY DEFAULT: Requires enable_privesc13 = true (creates target VM ~$2-5/mo)
#
# NOTE: This path demonstrates the risk of over-permissioned service accounts
# on VMs that have broad SSH access configured.

resource "google_service_account" "privesc13_existing_ssh" {
  count = var.enable_privesc13 ? 1 : 0

  account_id   = "${var.resource_prefix}13-existing-ssh"
  display_name = "Privesc13 - Existing SSH Access"
  description  = "Can escalate via existing SSH access to high-priv VM"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with minimal permissions - just enough to discover VMs and SSH
resource "google_project_iam_custom_role" "privesc13_existing_ssh" {
  count = var.enable_privesc13 ? 1 : 0

  role_id     = "${var.resource_prefix}_13_existingSSH"
  title       = "Privesc13 - Existing SSH Access"
  description = "Minimal permissions for SSH access when key is already in metadata"
  permissions = [
    # Discovery permissions
    "compute.instances.list",
    "compute.instances.get",
    "compute.zones.list",
    # Required for gcloud compute ssh
    "compute.projects.get",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc13_role" {
  count = var.enable_privesc13 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc13_existing_ssh[0].id
  member  = "serviceAccount:${google_service_account.privesc13_existing_ssh[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc13_impersonate" {
  count = var.enable_privesc13 ? 1 : 0

  service_account_id = google_service_account.privesc13_existing_ssh[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# NOTE: To complete the scenario, add your SSH key to project or instance metadata:
#
# Option 1: Project-level (access all instances)
#   gcloud compute project-info add-metadata \
#     --metadata-from-file=ssh-keys=<(echo "USERNAME:$(cat ~/.ssh/id_rsa.pub)")
#
# Option 2: Instance-level (access specific instance)
#   gcloud compute instances add-metadata privesc-instance \
#     --zone=us-central1-a \
#     --metadata-from-file=ssh-keys=<(echo "USERNAME:$(cat ~/.ssh/id_rsa.pub)")
#
# Then impersonate privesc13-existing-ssh and SSH to the instance.
