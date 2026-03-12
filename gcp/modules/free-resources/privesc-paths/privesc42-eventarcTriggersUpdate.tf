# Privesc Path 42: Eventarc Triggers Update (Hijack Existing Trigger)
#
# VULNERABILITY: A service account with eventarc.triggers.update and actAs
# can modify an existing Eventarc trigger to change its service account,
# redirecting event-driven execution to use a privileged SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List Eventarc triggers to find ones to hijack
#   3. Update the trigger's service account to a high-priv SA
#   4. Optionally change the trigger's destination (Cloud Run service)
#   5. Generate the triggering event
#   6. Your code executes with the new SA's permissions
#
# DETECTION: FoxMapper detects this via the eventarcTriggersUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack event-driven infrastructure
#
# NOTE: This path is DISABLED by default (enable_privesc42 = false)
#       Enable with: enable_privesc42 = true

resource "google_service_account" "privesc42_eventarc_update" {
  count = var.enable_privesc42 ? 1 : 0

  account_id   = "${var.resource_prefix}42-eventarc-upd"
  display_name = "Privesc42 - eventarc.triggers.update"
  description  = "Can escalate via Eventarc trigger update to change SA"
  project      = var.project_id

  depends_on = [time_sleep.batch10_delay]
}

# Custom role with Eventarc trigger update permissions
resource "google_project_iam_custom_role" "privesc42_eventarc_update" {
  count = var.enable_privesc42 ? 1 : 0

  role_id     = "${var.resource_prefix}_42_eventarc_update"
  title       = "Privesc42 Eventarc Trigger Updater"
  description = "Can update Eventarc triggers to change SA"
  project     = var.project_id

  permissions = [
    "eventarc.triggers.update",
    "eventarc.triggers.get",
    "eventarc.triggers.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc42_eventarc_update" {
  count = var.enable_privesc42 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc42_eventarc_update[0].id
  member  = "serviceAccount:${google_service_account.privesc42_eventarc_update[0].email}"
}

# Grant actAs on the high-privilege SA (to change trigger's SA)
resource "google_service_account_iam_member" "privesc42_actas" {
  count = var.enable_privesc42 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc42_eventarc_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc42_impersonate" {
  count = var.enable_privesc42 ? 1 : 0

  service_account_id = google_service_account.privesc42_eventarc_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
