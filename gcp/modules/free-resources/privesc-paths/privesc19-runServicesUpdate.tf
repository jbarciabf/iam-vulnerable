# Privesc Path 20: Cloud Run Services Update
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
#
# DISABLED BY DEFAULT: Requires enable_privesc20 = true (creates target service, free when idle)

resource "google_service_account" "privesc20_run_update" {
  count = var.enable_privesc20 ? 1 : 0

  account_id   = "${var.resource_prefix}20-run-update"
  display_name = "Privesc20 - run.services.update"
  description  = "Can escalate via run.services.update"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with run.services.update permission
resource "google_project_iam_custom_role" "privesc20_run_update" {
  count = var.enable_privesc20 ? 1 : 0

  role_id     = "${var.resource_prefix}_20_run_update"
  title       = "Privesc20 Cloud Run Updater"
  description = "Can update Cloud Run services"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "run.services.update",
    # Supporting permissions (required by gcloud)
    "run.services.get",
    "run.operations.get",
    "run.revisions.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc20_run_update" {
  count = var.enable_privesc20 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc20_run_update[0].id
  member  = "serviceAccount:${google_service_account.privesc20_run_update[0].email}"
}

# Grant actAs on the high-privilege SA (needed to change service identity)
resource "google_service_account_iam_member" "privesc20_actas" {
  count = var.enable_privesc20 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc20_run_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc20_impersonate" {
  count = var.enable_privesc20 ? 1 : 0

  service_account_id = google_service_account.privesc20_run_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
