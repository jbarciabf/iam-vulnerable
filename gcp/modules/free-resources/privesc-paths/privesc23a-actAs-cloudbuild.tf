# Privesc Path 23a: actAs + Cloud Build
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus cloudbuild.builds.create can run builds as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Submit a Cloud Build job that runs as the high-priv SA
#   3. The build steps execute with the high-priv SA's permissions
#   4. Exfiltrate credentials or perform privileged operations in build steps
#
# DETECTION: FoxMapper detects this via the actAs + cloudbuild edge checker
#
# REAL-WORLD IMPACT: Critical - CI/CD pipeline abuse
#
# PERMISSIONS BREAKDOWN:
#   Primary (Vulnerable):
#     - iam.serviceAccounts.actAs (via roles/iam.serviceAccountUser on target SA)
#     - cloudbuild.builds.create
#   Supporting (Required for exploitation):
#     - cloudbuild.builds.get (to check build status and view logs)
#     - logging.logEntries.list (to view build logs - optional but useful)

resource "google_service_account" "privesc23a_actas_cloudbuild" {
  account_id   = "${var.resource_prefix}23a-actas-cloudbuild"
  display_name = "Privesc23a - actAs + Cloud Build"
  description  = "Can escalate via Cloud Build with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc23a_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc23a_actas_cloudbuild.email}"
}

# Custom role with minimal Cloud Build permissions
resource "google_project_iam_custom_role" "privesc23a_cloudbuild" {
  role_id     = "${var.resource_prefix}_23a_cloudbuild"
  title       = "Privesc23a - Cloud Build Submit"
  description = "Minimal permissions for Cloud Build job submission with SA"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable)
    "cloudbuild.builds.create",
    # Supporting permissions (required for exploitation)
    "cloudbuild.builds.get",
    "cloudbuild.builds.list",
    # Utility permissions
    "cloudbuild.operations.get",
    "cloudbuild.operations.list",
  ]
}

# Grant Cloud Build permissions
resource "google_project_iam_member" "privesc23a_cloudbuild" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc23a_cloudbuild.id
  member  = "serviceAccount:${google_service_account.privesc23a_actas_cloudbuild.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc23a_impersonate" {
  service_account_id = google_service_account.privesc23a_actas_cloudbuild.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
