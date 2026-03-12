# Privesc Path 30: Dataflow Job
#
# VULNERABILITY: A service account with dataflow.jobs.create and actAs can
# create Dataflow jobs running with a high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Dataflow job that runs with high-priv SA
#   3. The job's workers have access to the SA's permissions
#   4. The job can read secrets, modify resources, etc.
#
# DETECTION: FoxMapper detects this via the dataflow edge checker
#
# REAL-WORLD IMPACT: High - Data pipeline abuse
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - dataflow.jobs.create
#   Supporting (Required for exploitation):
#     - dataflow.jobs.get (to check job status)
#     - compute.* (Dataflow uses GCE workers - handled by Dataflow service agent)

resource "google_service_account" "privesc30_dataflow" {
  account_id   = "${var.resource_prefix}30-dataflow"
  display_name = "Privesc30 - Dataflow"
  description  = "Can escalate via Dataflow job"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with minimal Dataflow permissions
resource "google_project_iam_custom_role" "privesc30_dataflow" {
  role_id     = "${var.resource_prefix}_30_dataflow"
  title       = "Privesc30 - Dataflow Job Creator"
  description = "Minimal permissions for Dataflow job creation with SA"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "dataflow.jobs.create",
    # Supporting permissions (required for exploitation)
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.jobs.cancel",
    "dataflow.messages.list",
    # Utility permissions
    "compute.regions.list",
    "compute.zones.list",
  ]
}

# Grant Dataflow permissions
resource "google_project_iam_member" "privesc30_dataflow" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc30_dataflow.id
  member  = "serviceAccount:${google_service_account.privesc30_dataflow.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc30_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc30_dataflow.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc30_impersonate" {
  service_account_id = google_service_account.privesc30_dataflow.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
