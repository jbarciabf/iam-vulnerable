# Privesc Path 43: Explicit Deny Bypass via Service Account Chaining
#
# VULNERABILITY: A service account that is explicitly denied permissions can
# still escalate by impersonating another SA that isn't denied.
#
# EXPLOITATION:
#   1. The attacker SA has explicit deny on sensitive actions
#   2. But the attacker SA can impersonate another SA (medium_priv)
#   3. The medium_priv SA is not denied the same actions
#   4. Impersonate medium_priv to bypass the deny
#
# DETECTION: FoxMapper detects this via privilege escalation path analysis
#
# REAL-WORLD IMPACT: High - Deny policy bypass

resource "google_service_account" "privesc43_deny_bypass" {
  account_id   = "${var.resource_prefix}16-deny-bypass"
  display_name = "Privesc16 - Deny Bypass"
  description  = "Can escalate by bypassing explicit deny via SA chaining"
  project      = var.project_id

  depends_on = [time_sleep.batch10_delay]
}

# Grant impersonation on the medium privilege SA
resource "google_service_account_iam_member" "privesc43_impersonate_medium" {
  service_account_id = google_service_account.medium_priv.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.privesc43_deny_bypass.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc43_impersonate" {
  service_account_id = google_service_account.privesc43_deny_bypass.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
