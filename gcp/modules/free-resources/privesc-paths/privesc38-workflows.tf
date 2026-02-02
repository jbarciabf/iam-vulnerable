# Privesc Path 38: Cloud Workflows with Privileged SA
#
# VULNERABILITY: A user with workflows.workflows.create and actAs can create
# Cloud Workflows that execute with a high-privilege service account.
#
# EXPLOITATION:
#   1. Create a Cloud Workflow with high-priv SA
#   2. Define workflow steps that make privileged API calls
#   3. Execute the workflow
#   4. Workflow runs with SA permissions, can modify IAM, etc.
#
# DETECTION: FoxMapper detects this via the workflowsCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Automated execution as privileged SA

resource "google_service_account" "privesc38_workflows" {
  account_id   = "${var.resource_prefix}38-workflows"
  display_name = "Privesc38 - Cloud Workflows"
  description  = "Can escalate via workflows.workflows.create"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Create a custom role with Workflows permissions
resource "google_project_iam_custom_role" "privesc38_workflows" {
  role_id     = "${var.resource_prefix}_38_workflows"
  title       = "Privesc38 Workflow Creator"
  description = "Can create Cloud Workflows"
  project     = var.project_id

  permissions = [
    "workflows.workflows.create",
    "workflows.workflows.get",
    "workflows.workflows.list",
    "workflows.executions.create",
    "workflows.executions.get",
    "workflows.operations.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc38_workflows" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc38_workflows.id
  member  = "serviceAccount:${google_service_account.privesc38_workflows.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc38_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc38_workflows.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc38_impersonate" {
  service_account_id = google_service_account.privesc38_workflows.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
