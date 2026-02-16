# Privesc Path 23b: Cloud Build Triggers Create
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

resource "google_service_account" "privesc23b_triggers" {
  account_id   = "${var.resource_prefix}23b-triggers"
  display_name = "Privesc23b - cloudbuild.triggers.create"
  description  = "Can escalate via cloudbuild.builds.create through triggers"
  project      = var.project_id

  depends_on = [time_sleep.batch5_delay]
}

# Create a custom role with build trigger permissions
resource "google_project_iam_custom_role" "privesc23b_triggers" {
  role_id     = "${var.resource_prefix}_23b_triggers"
  title       = "Privesc23b Build Trigger Creator"
  description = "Can create Cloud Build triggers"
  project     = var.project_id

  permissions = [
    # Primary permission (vulnerable) - cloudbuild.builds.create covers triggers.create()
    "cloudbuild.builds.create",
    # Supporting permissions
    "cloudbuild.builds.get",
    "cloudbuild.builds.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc23b_triggers" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc23b_triggers.id
  member  = "serviceAccount:${google_service_account.privesc23b_triggers.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc23b_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc23b_triggers.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc23b_impersonate" {
  service_account_id = google_service_account.privesc23b_triggers.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
