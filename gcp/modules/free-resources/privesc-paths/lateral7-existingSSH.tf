# Lateral Movement Path 7: Existing SSH Access to High-Priv VM
#
# CATEGORY: Lateral Movement (NOT Privilege Escalation)
# This path demonstrates data access via existing SSH credentials, not
# exploiting a permission to gain higher privileges.
#
# SCENARIO: Your SSH key is already in project or instance metadata
# (added by an admin). You discover a VM running with a high-privilege
# service account and SSH to it to steal credentials from the metadata server.
#
# EXPLOITATION:
#   1. SSH to the instance (your key is already authorized)
#   2. Access the metadata server to get tokens for the attached SA
#
# DETECTION: Hard to detect - attacker is using legitimate SSH access
#
# REAL-WORLD IMPACT: High - Legitimate access leads to credential theft
#
# DISABLED BY DEFAULT: Requires enable_lateral7 = true (creates target VM ~$6-7/mo)

resource "google_service_account" "lateral7_existing_ssh" {
  count = var.enable_lateral7 ? 1 : 0

  account_id   = "${var.resource_prefix}-lateral7-ssh"
  display_name = "Lateral7 - Existing SSH Access"
  description  = "Lateral movement via existing SSH access to high-priv VM"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "lateral7_impersonate" {
  count = var.enable_lateral7 ? 1 : 0

  service_account_id = google_service_account.lateral7_existing_ssh[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
