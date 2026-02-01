# False Positive Test 4: No Viable Target
#
# SCENARIO: A service account has actAs permission, but there are no
# privileged service accounts to impersonate.
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD NOT report this as a privilege escalation path
#   - There's no target SA that would result in escalation
#
# WHY IT'S A FALSE POSITIVE IF FLAGGED:
#   - actAs alone doesn't mean escalation if there's no privileged target
#   - Tools should verify the target SA has elevated privileges

resource "google_service_account" "fp4_no_target" {
  account_id   = "${var.resource_prefix}-fp4-notarget"
  display_name = "FP4 - No Viable Target"
  description  = "Has actAs but only on unprivileged SA"
  project      = var.project_id
}

# Create an unprivileged service account as the only target
resource "google_service_account" "fp4_unprivileged_target" {
  account_id   = "${var.resource_prefix}-fp4-unpriv"
  display_name = "FP4 - Unprivileged Target"
  description  = "Has no special permissions"
  project      = var.project_id
}

# This SA has NO roles at all - it's completely unprivileged
# (no google_project_iam_member for this SA)

# Grant actAs only on the unprivileged target
resource "google_service_account_iam_member" "fp4_actas_unpriv" {
  service_account_id = google_service_account.fp4_unprivileged_target.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.fp4_no_target.email}"
}

# Allow attacker to impersonate
resource "google_service_account_iam_member" "fp4_impersonate" {
  service_account_id = google_service_account.fp4_no_target.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
