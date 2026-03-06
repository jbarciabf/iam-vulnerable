# Privesc Path 32: Dataflow Update (Hijack Existing Streaming Job)
#
# VULNERABILITY: A service account with dataflow.jobs.updateContents and
# dataflow.jobs.cancel can hijack existing streaming Dataflow jobs by
# cancelling the running job and replacing it with a malicious one that
# inherits the original job's service account.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List existing Dataflow jobs to find streaming jobs with privileged SAs
#   3. Cancel the target streaming job
#   4. Launch a replacement job with the same name/config but malicious code
#   5. The new job runs with the original job's SA permissions
#
# DETECTION: FoxMapper detects this via the dataflowUpdate edge checker
#
# REAL-WORLD IMPACT: High - Hijack data pipelines and abuse their SA
#
# NOTE: This path requires an existing streaming Dataflow job as target.
#       Enable with: enable_privesc32 = true (creates target infrastructure)
#       The target job is in modules/non-free-resources/dataflow/

resource "google_service_account" "privesc32_dataflow_update" {
  count = var.enable_privesc32 ? 1 : 0

  account_id   = "${var.resource_prefix}32-dataflow-upd"
  display_name = "Privesc32 - Dataflow Update"
  description  = "Can escalate via dataflow.jobs.updateContents + cancel"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with Dataflow update permissions (no actAs needed - hijacks existing job's SA)
resource "google_project_iam_custom_role" "privesc32_dataflow_update" {
  count = var.enable_privesc32 ? 1 : 0

  role_id     = "${var.resource_prefix}_32_dataflow_update"
  title       = "Privesc32 Dataflow Job Updater"
  description = "Can update/cancel Dataflow jobs to hijack their SA"
  project     = var.project_id

  permissions = [
    "dataflow.jobs.updateContents",
    "dataflow.jobs.cancel",
    "dataflow.jobs.get",
    "dataflow.jobs.list",
    "dataflow.messages.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc32_dataflow_update" {
  count = var.enable_privesc32 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc32_dataflow_update[0].id
  member  = "serviceAccount:${google_service_account.privesc32_dataflow_update[0].email}"
}

# No actAs binding needed - the attacker hijacks an existing job's SA

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc32_impersonate" {
  count = var.enable_privesc32 ? 1 : 0

  service_account_id = google_service_account.privesc32_dataflow_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
