# Privesc Path 24: Cloud Build Trigger Update
#
# VULNERABILITY: A service account with cloudbuild.builds.editor role can update
# existing Cloud Build triggers to change the service account and inject malicious build steps.
#
# PREREQUISITE: Path 23b must be completed first (creates privesc23b-trigger)
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Export the existing trigger configuration (created by 23b)
#   3. Modify the trigger to use privesc24-high-priv-sa and inject malicious build steps
#   4. Import the modified trigger to hijack it
#   5. Run the trigger to execute as the new high-priv SA
#
# DETECTION: FoxMapper detects this via the cloudbuildBuildsUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack existing CI/CD pipelines and swap service accounts

# High-privilege target SA for path 24 (different from main high_priv SA)
# This allows demonstrating the SA swap in the trigger update
resource "google_service_account" "privesc24_high_priv" {
  account_id   = "${var.resource_prefix}24-high-priv-sa"
  display_name = "Privesc24 High Priv SA"
  description  = "High-privilege SA for privesc24 - target for trigger SA swap"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Grant high privileges to this SA (Owner role)
resource "google_project_iam_member" "privesc24_high_priv_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.privesc24_high_priv.email}"
}

# Attacker SA that can update builds
resource "google_service_account" "privesc24_builds_update" {
  account_id   = "${var.resource_prefix}24-builds-update"
  display_name = "Privesc24 - cloudbuild.builds.update"
  description  = "Can escalate by updating existing Cloud Build triggers"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Cloud Build Editor role includes trigger update permissions
# (cloudbuild.triggers.* permissions not available in custom roles)
resource "google_project_iam_member" "privesc24_cloudbuild_editor" {
  project = var.project_id
  role    = "roles/cloudbuild.builds.editor"
  member  = "serviceAccount:${google_service_account.privesc24_builds_update.email}"
}

# Service Usage Consumer required to run gcloud builds commands
resource "google_project_iam_member" "privesc24_service_usage" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.privesc24_builds_update.email}"
}

# Grant actAs on the privesc24 high-privilege SA (target SA for swap)
resource "google_service_account_iam_member" "privesc24_actas" {
  service_account_id = google_service_account.privesc24_high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc24_builds_update.email}"
}

# Grant actAs on the original high-priv SA (required to update trigger that uses it)
# Per GCP docs: "user can update a trigger as long as they have iam.serviceAccounts.actAs
# permissions on both the previously configured service account and the new service account"
resource "google_service_account_iam_member" "privesc24_actas_original" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc24_builds_update.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc24_impersonate" {
  service_account_id = google_service_account.privesc24_builds_update.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
