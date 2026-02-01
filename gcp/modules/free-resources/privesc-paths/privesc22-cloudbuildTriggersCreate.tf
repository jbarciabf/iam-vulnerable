# Privesc Path 22: Cloud Build Triggers Create
#
# VULNERABILITY: A service account with cloudbuild.builds.create via trigger
# can create build triggers that execute builds with elevated privileges
# when repository events occur.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a build trigger linked to a repository
#   3. Configure the trigger to run as a high-privilege SA
#   4. Push to the repository to trigger the build
#   5. Build executes with the SA's permissions
#
# DETECTION: FoxMapper detects this via the cloudbuildTriggersCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Persistent build access as privileged SA

resource "google_service_account" "privesc22_triggers" {
  account_id   = "${var.resource_prefix}22-build-triggers"
  display_name = "Privesc22 - cloudbuild.triggers.create"
  description  = "Can escalate via cloudbuild.builds.create through triggers"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with build trigger permissions
resource "google_project_iam_custom_role" "privesc22_triggers" {
  role_id     = "${var.resource_prefix}_22_triggers"
  title       = "Privesc22 Build Trigger Creator"
  description = "Can create Cloud Build triggers"
  project     = var.project_id

  permissions = [
    "cloudbuild.builds.create",
    "cloudbuild.builds.get",
    "cloudbuild.builds.list",
    "source.repos.get",
    "source.repos.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc22_triggers" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc22_triggers.id
  member  = "serviceAccount:${google_service_account.privesc22_triggers.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc22_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc22_triggers.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc22_impersonate" {
  service_account_id = google_service_account.privesc22_triggers.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
