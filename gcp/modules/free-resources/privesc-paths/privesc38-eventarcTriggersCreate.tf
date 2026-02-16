# Privesc Path 38: Eventarc Triggers Create
#
# VULNERABILITY: A service account with eventarc.triggers.create and actAs
# can create Eventarc triggers that invoke Cloud Run or other services
# with a high-privilege service account when events occur.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create an Eventarc trigger for a common event (e.g., Pub/Sub, Audit Log)
#   3. Configure the trigger to run a Cloud Run service as a privileged SA
#   4. Generate the triggering event
#   5. Your code executes with the SA's permissions
#
# DETECTION: FoxMapper detects this via the eventarcTriggersCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Event-driven code execution as privileged SA

resource "google_service_account" "privesc38_eventarc" {
  account_id   = "${var.resource_prefix}38-eventarc"
  display_name = "Privesc38 - eventarc.triggers.create"
  description  = "Can escalate via Eventarc trigger creation"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Create a custom role with Eventarc trigger permissions
resource "google_project_iam_custom_role" "privesc38_eventarc" {
  role_id     = "${var.resource_prefix}_38_eventarc"
  title       = "Privesc38 Eventarc Trigger Creator"
  description = "Can create Eventarc triggers"
  project     = var.project_id

  permissions = [
    "eventarc.triggers.create",
    "eventarc.triggers.get",
    "eventarc.triggers.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc38_eventarc" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc38_eventarc.id
  member  = "serviceAccount:${google_service_account.privesc38_eventarc.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc38_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc38_eventarc.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc38_impersonate" {
  service_account_id = google_service_account.privesc38_eventarc.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
