# Privesc Path 19: Cloud Run Services Update
#
# VULNERABILITY: A service account with run.services.update can modify
# existing Cloud Run services, including changing the container image
# or attached service account.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Update an existing Cloud Run service
#   3. Change the container to a malicious image OR change the attached SA
#   4. Invoke the service to execute as the service's SA
#
# DETECTION: FoxMapper detects this via the runServicesUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Can hijack existing services

resource "google_service_account" "privesc19_run_update" {
  account_id   = "${var.resource_prefix}19-run-update"
  display_name = "Privesc19 - run.services.update"
  description  = "Can escalate via run.services.update"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with run.services.update permission
resource "google_project_iam_custom_role" "privesc19_run_update" {
  role_id     = "${var.resource_prefix}_19_run_update"
  title       = "Privesc19 Cloud Run Updater"
  description = "Can update Cloud Run services"
  project     = var.project_id

  permissions = [
    "run.services.update",
    "run.services.get",
    "run.services.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc19_run_update" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc19_run_update.id
  member  = "serviceAccount:${google_service_account.privesc19_run_update.email}"
}

# Grant actAs on the high-privilege SA (needed to change service identity)
resource "google_service_account_iam_member" "privesc19_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc19_run_update.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc19_impersonate" {
  service_account_id = google_service_account.privesc19_run_update.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
