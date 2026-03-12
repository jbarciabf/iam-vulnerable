# Privesc Path 21: Cloud Run Jobs with Privileged SA
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
#
# COST: < $0.10/month (Cloud Build, Artifact Registry, Cloud Run)
#
# NOTE: Disabled by default. Enable with enable_privesc21 = true

resource "google_service_account" "privesc21_run_jobs" {
  count = var.enable_privesc21 ? 1 : 0

  account_id   = "${var.resource_prefix}21-run-jobs"
  display_name = "Privesc21 - Cloud Run Jobs"
  description  = "Can escalate via run.jobs.create"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with Cloud Run jobs permissions
resource "google_project_iam_custom_role" "privesc21_run_jobs" {
  count = var.enable_privesc21 ? 1 : 0

  role_id     = "${var.resource_prefix}_21_run_jobs"
  title       = "Privesc21 Cloud Run Jobs Creator"
  description = "Can create Cloud Run jobs"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "run.jobs.create",
    # Supporting permissions (required by gcloud)
    "run.jobs.get",
    "run.jobs.run",
    "run.executions.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc21_run_jobs" {
  count = var.enable_privesc21 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc21_run_jobs[0].id
  member  = "serviceAccount:${google_service_account.privesc21_run_jobs[0].email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc21_actas" {
  count = var.enable_privesc21 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc21_run_jobs[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc21_impersonate" {
  count = var.enable_privesc21 ? 1 : 0

  service_account_id = google_service_account.privesc21_run_jobs[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
