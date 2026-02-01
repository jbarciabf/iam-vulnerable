# False Positive Test 3: Scope-Limited Permission
#
# SCENARIO: A service account can only create service account keys for
# itself, not for other (privileged) service accounts.
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD NOT report this as a privilege escalation path
#   - The permission is scoped only to the SA itself
#
# WHY IT'S A FALSE POSITIVE IF FLAGGED:
#   - Creating a key for yourself doesn't escalate privileges
#   - Tools should check the resource scope of permissions

resource "google_service_account" "fp3_scope_limited" {
  account_id   = "${var.resource_prefix}-fp3-scope"
  display_name = "FP3 - Scope Limited"
  description  = "Can only create keys for itself"
  project      = var.project_id

  depends_on = [time_sleep.tt_batch1_delay]
}

# Grant key creation only on itself (using SA-level IAM, not project-level)
resource "google_service_account_iam_member" "fp3_self_key_admin" {
  service_account_id = google_service_account.fp3_scope_limited.name
  role               = "roles/iam.serviceAccountKeyAdmin"
  member             = "serviceAccount:${google_service_account.fp3_scope_limited.email}"
}

# This SA does NOT have project-level key creation permissions
# So it cannot create keys for other SAs

# Allow attacker to impersonate
resource "google_service_account_iam_member" "fp3_impersonate" {
  service_account_id = google_service_account.fp3_scope_limited.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
