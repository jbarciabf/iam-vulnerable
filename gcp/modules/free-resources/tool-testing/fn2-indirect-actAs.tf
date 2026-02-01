# False Negative Test 2: Indirect actAs via Group
#
# SCENARIO: A service account doesn't have direct actAs, but is a member
# of a group that has actAs on a high-priv SA.
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD detect the escalation path through group membership
#
# WHY IT'S A FALSE NEGATIVE IF MISSED:
#   - Group-based permissions are often overlooked
#   - The SA can still escalate via the group membership

# Note: This test requires a Google Group to be created externally
# and the service account added to it. The group then gets actAs permission.

resource "google_service_account" "fn2_indirect_actas" {
  account_id   = "${var.resource_prefix}-fn2-indirect"
  display_name = "FN2 - Indirect actAs"
  description  = "Has indirect actAs via group membership (requires external group setup)"
  project      = var.project_id
}

# High-privilege SA for this test
resource "google_service_account" "fn2_target" {
  account_id   = "${var.resource_prefix}-fn2-target"
  display_name = "FN2 - Target SA"
  description  = "Target for indirect actAs test"
  project      = var.project_id
}

# Grant Editor to the target SA
resource "google_project_iam_member" "fn2_target_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.fn2_target.email}"
}

# For testing: Direct impersonation path (simulating what a group would provide)
# In a real scenario, this would be granted to a group instead
resource "google_service_account_iam_member" "fn2_indirect_impersonate" {
  service_account_id = google_service_account.fn2_target.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.fn2_indirect_actas.email}"
}

# Allow attacker to impersonate
resource "google_service_account_iam_member" "fn2_attacker_impersonate" {
  service_account_id = google_service_account.fn2_indirect_actas.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
