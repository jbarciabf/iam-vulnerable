# False Positive Test 1: Non-Exploitable Restrictive Condition
#
# SCENARIO: A service account has setIamPolicy but with a condition that
# truly restricts exploitation (e.g., requires an attribute that can't be forged).
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD NOT report this as a privilege escalation path
#   - The condition actually prevents the escalation
#
# WHY IT'S A FALSE POSITIVE IF FLAGGED:
#   - Conditions that require specific resource tags or labels that
#     the attacker cannot set should not be exploitable

resource "google_service_account" "fp1_restrictive_condition" {
  account_id   = "${var.resource_prefix}-fp1-restrict"
  display_name = "FP1 - Restrictive Condition"
  description  = "Has setIamPolicy but with truly restrictive condition"
  project      = var.project_id
}

# Custom role with setIamPolicy
resource "google_project_iam_custom_role" "fp1_role" {
  role_id     = "${var.resource_prefix}_fp1_role"
  title       = "FP1 - setIamPolicy Restricted"
  description = "Test: setIamPolicy with non-exploitable condition"
  permissions = [
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
  ]
  project = var.project_id
}

# Grant with a condition that requires a specific resource tag
# This cannot be exploited because the condition checks resource attributes
resource "google_project_iam_member" "fp1_role_binding" {
  project = var.project_id
  role    = google_project_iam_custom_role.fp1_role.id
  member  = "serviceAccount:${google_service_account.fp1_restrictive_condition.email}"

  condition {
    title       = "require-sandbox-label"
    description = "Only applies to resources with sandbox=true label"
    expression  = "resource.matchLabels('sandbox', 'true')"
  }
}

# Allow attacker to impersonate
resource "google_service_account_iam_member" "fp1_impersonate" {
  service_account_id = google_service_account.fp1_restrictive_condition.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
