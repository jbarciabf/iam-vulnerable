# Privesc Path 19: actAs + Cloud Run Deployment
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus run.services.create can deploy a Cloud Run service as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Deploy a Cloud Run service with the high-priv SA
#   3. The container can access GCP APIs as the high-priv SA
#   4. Send requests to the service to execute privileged operations
#
# DETECTION: FoxMapper detects this via the actAs + run edge checker
#
# REAL-WORLD IMPACT: Critical - Container-based privilege escalation
#
# COST: < $0.10/month (Cloud Build, Artifact Registry, Cloud Run)
#
# NOTE: Disabled by default. Enable with enable_privesc19 = true
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - run.services.create
#   Supporting (Required for exploitation):
#     - run.services.get (to check deployment status)
#     - run.operations.get (to monitor deployment)

resource "google_service_account" "privesc19_actas_cloudrun" {
  count = var.enable_privesc19 ? 1 : 0

  account_id   = "${var.resource_prefix}19-actas-cloudrun"
  display_name = "Privesc19 - actAs + Cloud Run"
  description  = "Can escalate via Cloud Run with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc19_actas" {
  count = var.enable_privesc19 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc19_actas_cloudrun[0].email}"
}

# Custom role with minimal Cloud Run permissions
resource "google_project_iam_custom_role" "privesc19_run" {
  count = var.enable_privesc19 ? 1 : 0

  role_id     = "${var.resource_prefix}_19_cloudrun"
  title       = "Privesc19 - Cloud Run Deploy"
  description = "Minimal permissions for Cloud Run deployment with SA"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "run.services.create",
    # Supporting permissions (required for exploitation)
    "run.services.get",
    "run.services.list",
    "run.services.update",
    "run.operations.get",
    "run.operations.list",
    # Utility permissions
    "run.services.delete",
    "run.locations.list",
  ]
}

# Grant Cloud Run permissions
resource "google_project_iam_member" "privesc19_run" {
  count = var.enable_privesc19 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc19_run[0].id
  member  = "serviceAccount:${google_service_account.privesc19_actas_cloudrun[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc19_impersonate" {
  count = var.enable_privesc19 ? 1 : 0

  service_account_id = google_service_account.privesc19_actas_cloudrun[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
