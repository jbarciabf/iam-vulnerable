# Privesc Path 22: Cloud Run Jobs Update
#
# VULNERABILITY: A user with run.jobs.update and actAs can update existing
# Cloud Run jobs to execute with a high-privilege service account.
#
# EXPLOITATION:
#   1. Update an existing Cloud Run job with malicious container image
#   2. Configure job to use high-privilege SA
#   3. Execute the job with access to SA credentials
#   4. Exfiltrate token or make privileged API calls
#
# DETECTION: FoxMapper detects this via the runJobsUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack existing jobs to run as privileged SA
#
# COST: < $0.10/month (Cloud Build, Artifact Registry, Cloud Run)
#
# NOTE: Disabled by default. Enable with enable_privesc22 = true

resource "google_service_account" "privesc22_run_jobs_update" {
  count = var.enable_privesc22 ? 1 : 0

  account_id   = "${var.resource_prefix}22-run-jobs-update"
  display_name = "Privesc22 - Cloud Run Jobs Update"
  description  = "Can escalate via run.jobs.update"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with Cloud Run jobs update permissions
resource "google_project_iam_custom_role" "privesc22_run_jobs_update" {
  count = var.enable_privesc22 ? 1 : 0

  role_id     = "${var.resource_prefix}_22_run_jobs_update"
  title       = "Privesc22 Cloud Run Jobs Updater"
  description = "Can update Cloud Run jobs"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "run.jobs.update",
    # Supporting permissions (required by gcloud)
    "run.jobs.get",
    "run.jobs.run",
    "run.executions.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc22_run_jobs_update" {
  count = var.enable_privesc22 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc22_run_jobs_update[0].id
  member  = "serviceAccount:${google_service_account.privesc22_run_jobs_update[0].email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc22_actas" {
  count = var.enable_privesc22 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc22_run_jobs_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc22_impersonate" {
  count = var.enable_privesc22 ? 1 : 0

  service_account_id = google_service_account.privesc22_run_jobs_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
