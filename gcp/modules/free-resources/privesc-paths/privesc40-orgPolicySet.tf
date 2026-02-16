# Privesc Path 40: Organization Policy Set
#
# VULNERABILITY: A service account with orgpolicy.policy.set at the project
# or organization level can modify organizational policies that enforce
# security controls, potentially disabling critical safeguards.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Modify organization policies to allow:
#      - Public access to Cloud Storage buckets
#      - Service account key creation
#      - External IP addresses on VMs
#   3. Exploit the weakened security controls
#
# DETECTION: FoxMapper detects this via the orgPolicySet edge checker
#
# REAL-WORLD IMPACT: Critical - Can disable security guardrails
#
# NOTE: This path is DISABLED by default (enable_privesc40 = false) because
#       it requires a GCP Organization. The orgpolicy.policy.set permission
#       cannot be added to custom roles at the project level - it requires the
#       predefined orgpolicy.policyAdmin role granted at org level.
#
# Enable with: enable_privesc40 = true (requires gcp_organization_id)

resource "google_service_account" "privesc40_org_policy" {
  count = var.enable_privesc40 ? 1 : 0

  account_id   = "${var.resource_prefix}40-org-policy"
  display_name = "Privesc40 - orgpolicy.policy.set"
  description  = "Can escalate via organization policy modification"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Use the predefined Org Policy Admin role
# Note: orgpolicy.policy.set cannot be added to custom roles at project level
# The SA gets the role, but actual policy modification requires org-level grant
resource "google_project_iam_member" "privesc40_org_policy" {
  count = var.enable_privesc40 ? 1 : 0

  project = var.project_id
  role    = "roles/orgpolicy.policyAdmin"
  member  = "serviceAccount:${google_service_account.privesc40_org_policy[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc40_impersonate" {
  count = var.enable_privesc40 ? 1 : 0

  service_account_id = google_service_account.privesc40_org_policy[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
