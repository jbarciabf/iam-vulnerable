# Privesc Path 27: Cloud Run Jobs with Privileged SA
#
# VULNERABILITY: A user with run.jobs.create and actAs can create Cloud Run
# jobs that execute with a high-privilege service account.
#
# EXPLOITATION:
#   1. Create a Cloud Run job with malicious container image
#   2. Configure job to use high-privilege SA
#   3. Job executes with access to SA credentials
#   4. Exfiltrate token or make privileged API calls
#
# DETECTION: FoxMapper detects this via the runJobsCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Arbitrary code execution as privileged SA

resource "google_service_account" "privesc27_run_jobs" {
  account_id   = "${var.resource_prefix}27-run-jobs"
  display_name = "Privesc27 - Cloud Run Jobs"
  description  = "Can escalate via run.jobs.create"
  project      = var.project_id
}

# Create a custom role with Cloud Run jobs permissions
resource "google_project_iam_custom_role" "privesc27_run_jobs" {
  role_id     = "${var.resource_prefix}_27_run_jobs"
  title       = "Privesc27 Cloud Run Jobs Creator"
  description = "Can create Cloud Run jobs"
  project     = var.project_id

  permissions = [
    "run.jobs.create",
    "run.jobs.get",
    "run.jobs.list",
    "run.jobs.run",
    "run.executions.get",
    "run.executions.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc27_run_jobs" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc27_run_jobs.id
  member  = "serviceAccount:${google_service_account.privesc27_run_jobs.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc27_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc27_run_jobs.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc27_impersonate" {
  service_account_id = google_service_account.privesc27_run_jobs.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
