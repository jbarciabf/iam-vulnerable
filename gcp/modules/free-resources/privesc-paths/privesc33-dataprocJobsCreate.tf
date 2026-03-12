# Privesc Path 33: Dataproc Jobs Create
#
# VULNERABILITY: A service account with dataproc.jobs.create can submit
# jobs to existing Dataproc clusters, executing code with the cluster's
# service account permissions.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find an existing Dataproc cluster with a privileged SA
#   3. Submit a job (Spark, PySpark, Hadoop) with malicious code
#   4. The job runs with the cluster's SA permissions
#   5. Exfiltrate SA token from the job's environment
#
# DETECTION: FoxMapper detects this via the dataprocJobsCreate edge checker
#
# REAL-WORLD IMPACT: High - Code execution on existing Dataproc clusters

resource "google_service_account" "privesc33_dataproc_jobs" {
  account_id   = "${var.resource_prefix}33-dataproc-jobs"
  display_name = "Privesc33 - dataproc.jobs.create"
  description  = "Can escalate via dataproc.jobs.create"
  project      = var.project_id

  depends_on = [time_sleep.batch8_delay]
}

# Create a custom role with Dataproc job permissions
resource "google_project_iam_custom_role" "privesc33_dataproc_jobs" {
  role_id     = "${var.resource_prefix}_33_dataproc_jobs"
  title       = "Privesc33 Dataproc Job Submitter"
  description = "Can submit jobs to Dataproc clusters"
  project     = var.project_id

  permissions = [
    "dataproc.jobs.create",
    "dataproc.jobs.get",
    "dataproc.jobs.list",
    "dataproc.clusters.get",
    "dataproc.clusters.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc33_dataproc_jobs" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc33_dataproc_jobs.id
  member  = "serviceAccount:${google_service_account.privesc33_dataproc_jobs.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc33_impersonate" {
  service_account_id = google_service_account.privesc33_dataproc_jobs.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
