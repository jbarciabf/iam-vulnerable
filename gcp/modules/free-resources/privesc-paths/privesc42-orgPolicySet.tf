# Privesc Path 42: Organization Policy Set
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
# NOTE: Org policy changes require appropriate organization-level permissions
#       This path demonstrates the project-level configuration

resource "google_service_account" "privesc42_org_policy" {
  account_id   = "${var.resource_prefix}42-org-policy"
  display_name = "Privesc42 - orgpolicy.policy.set"
  description  = "Can escalate via organization policy modification"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Create a custom role with Org Policy permissions
resource "google_project_iam_custom_role" "privesc42_org_policy" {
  role_id     = "${var.resource_prefix}_42_org_policy"
  title       = "Privesc42 Org Policy Admin"
  description = "Can modify organization policies"
  project     = var.project_id

  permissions = [
    "orgpolicy.policy.set",
    "orgpolicy.policy.get",
    "orgpolicy.constraints.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc42_org_policy" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc42_org_policy.id
  member  = "serviceAccount:${google_service_account.privesc42_org_policy.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc42_impersonate" {
  service_account_id = google_service_account.privesc42_org_policy.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
