# Privesc Path 21: actAs + Cloud Build
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

resource "google_service_account" "privesc21_actas_cloudbuild" {
  account_id   = "${var.resource_prefix}21-actas-cloudbuild"
  display_name = "Privesc21 - actAs + Cloud Build"
  description  = "Can escalate via Cloud Build with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc21_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc21_actas_cloudbuild.email}"
}

# Grant Cloud Build editor permissions
resource "google_project_iam_member" "privesc21_cloudbuild" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.privesc21_actas_cloudbuild.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc21_impersonate" {
  service_account_id = google_service_account.privesc21_actas_cloudbuild.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
