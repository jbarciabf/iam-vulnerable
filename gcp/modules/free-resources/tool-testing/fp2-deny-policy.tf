# False Positive Test 2: Explicit Deny Policy
#
# SCENARIO: A service account has setIamPolicy permissions but is explicitly
# denied by an organization policy or deny policy.
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD NOT report this as a privilege escalation path
#   - Deny policies override allow policies
#
# WHY IT'S A FALSE POSITIVE IF FLAGGED:
#   - Deny policies (when properly configured) prevent the action
#   - Tools should evaluate deny policies

# Note: This test demonstrates the pattern, but org-level deny policies
# must be created separately as they require org-level permissions

resource "google_service_account" "fp2_denied" {
  account_id   = "${var.resource_prefix}-fp2-denied"
  display_name = "FP2 - Explicitly Denied"
  description  = "Has setIamPolicy but should be denied by policy"
  project      = var.project_id
}

# Grant setIamPolicy through Editor role
resource "google_project_iam_member" "fp2_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.fp2_denied.email}"
}

# Note: To complete this test, you would need to create an organization-level
# deny policy that explicitly denies this SA from calling setIamPolicy.
# Example deny policy rule:
#
# deniedPermissions:
#   - "iam.googleapis.com/serviceAccounts.setIamPolicy"
#   - "cloudresourcemanager.googleapis.com/projects.setIamPolicy"
# deniedPrincipals:
#   - "serviceAccount:${google_service_account.fp2_denied.email}"

# Allow attacker to impersonate
resource "google_service_account_iam_member" "fp2_impersonate" {
  service_account_id = google_service_account.fp2_denied.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
