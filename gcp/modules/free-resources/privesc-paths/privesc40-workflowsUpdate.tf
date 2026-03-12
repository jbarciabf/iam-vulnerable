# Privesc Path 41: Cloud Workflows Update (Hijack Existing Workflow)
#
# VULNERABILITY: A service account with workflows.workflows.update and actAs
# can modify an existing Cloud Workflow to change its service account and/or
# source code, then execute it with the new privileged SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List workflows to find ones with privileged SAs or update targets
#   3. Update the workflow's service account to a high-priv SA
#   4. Optionally modify the workflow source to exfiltrate tokens
#   5. Execute the workflow
#   6. Workflow runs with the new SA's permissions
#
# DETECTION: FoxMapper detects this via the workflowsUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack existing workflows for privileged execution
#
# NOTE: This path is DISABLED by default (enable_privesc41 = false)
#       Enable with: enable_privesc41 = true

resource "google_service_account" "privesc41_workflows_update" {
  count = var.enable_privesc41 ? 1 : 0

  account_id   = "${var.resource_prefix}41-workflows-upd"
  display_name = "Privesc41 - workflows.workflows.update"
  description  = "Can escalate via workflow update to change SA"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Custom role with Workflows update permissions
resource "google_project_iam_custom_role" "privesc41_workflows_update" {
  count = var.enable_privesc41 ? 1 : 0

  role_id     = "${var.resource_prefix}_41_workflows_update"
  title       = "Privesc41 Workflow Updater"
  description = "Can update Cloud Workflows to change SA and source"
  project     = var.project_id

  permissions = [
    "workflows.workflows.update",
    "workflows.workflows.get",
    "workflows.workflows.list",
    "workflows.executions.create",
    "workflows.executions.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc41_workflows_update" {
  count = var.enable_privesc41 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc41_workflows_update[0].id
  member  = "serviceAccount:${google_service_account.privesc41_workflows_update[0].email}"
}

# Grant actAs on the high-privilege SA (to change workflow's SA)
resource "google_service_account_iam_member" "privesc41_actas" {
  count = var.enable_privesc41 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc41_workflows_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc41_impersonate" {
  count = var.enable_privesc41 ? 1 : 0

  service_account_id = google_service_account.privesc41_workflows_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
