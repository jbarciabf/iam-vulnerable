# Privesc Path 41: Explicit Deny Bypass via Service Account Chaining
#
# VULNERABILITY: A service account that is explicitly denied permissions can
# still escalate by impersonating another SA that isn't denied.
#
# EXPLOITATION:
#   1. The attacker SA has explicit deny on sensitive actions
#   2. But the attacker SA can impersonate another SA (privesc41-medium-priv-sa)
#   3. The medium-priv SA is not denied the same actions
#   4. Impersonate medium-priv to bypass the deny
#
# DETECTION: FoxMapper detects this via privilege escalation path analysis
#
# REAL-WORLD IMPACT: High - Deny policy bypass
#
# RESOURCES:
#   - privesc41-deny-bypass: Starting SA (attacker impersonates this)
#   - privesc41-medium-priv-sa: Intermediate SA used to bypass deny policies

resource "google_service_account" "privesc41_deny_bypass" {
  account_id   = "${var.resource_prefix}41-deny-bypass"
  display_name = "Privesc41 - Deny Bypass"
  description  = "Can escalate by bypassing explicit deny via SA chaining"
  project      = var.project_id

  depends_on = [time_sleep.batch10_delay]
}

# Medium-privilege SA specific to Path 40
# This SA is NOT subject to the deny policy, allowing bypass
resource "google_service_account" "privesc41_medium_priv" {
  account_id   = "${var.resource_prefix}41-medium-priv-sa"
  display_name = "Privesc41 - Medium Privilege SA"
  description  = "Intermediate SA for path 40 deny bypass - not subject to deny policies"
  project      = var.project_id

  depends_on = [time_sleep.batch10_delay]
}

# Grant Editor role to the medium-priv SA (can do most things except IAM)
resource "google_project_iam_member" "privesc41_medium_priv_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.privesc41_medium_priv.email}"
}

# Grant impersonation on the medium privilege SA
resource "google_service_account_iam_member" "privesc41_impersonate_medium" {
  service_account_id = google_service_account.privesc41_medium_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.privesc41_deny_bypass.email}"
}

# Allow the attacker to impersonate the starting service account
resource "google_service_account_iam_member" "privesc41_impersonate" {
  service_account_id = google_service_account.privesc41_deny_bypass.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
