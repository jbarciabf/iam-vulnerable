# Privesc Path 25: Cloud Scheduler Create
#
# VULNERABILITY: A service account with cloudscheduler.jobs.create and actAs
# can create scheduled jobs that invoke targets with high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Cloud Scheduler job with high-priv SA as the OIDC identity
#   3. The job invokes an HTTP target with the SA's credentials
#   4. The target can be attacker-controlled to capture tokens
#
# DETECTION: FoxMapper detects this via scheduler edge checker
#
# REAL-WORLD IMPACT: High - Scheduled task abuse, token theft

resource "google_service_account" "privesc25_scheduler" {
  account_id   = "${var.resource_prefix}25-scheduler"
  display_name = "Privesc25 - Cloud Scheduler Create"
  description  = "Can escalate via cloudscheduler.jobs.create"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with Scheduler create permissions
resource "google_project_iam_custom_role" "privesc25_scheduler" {
  role_id     = "${var.resource_prefix}_25_scheduler"
  title       = "Privesc25 - Cloud Scheduler Create"
  description = "Vulnerable: Can create Cloud Scheduler jobs"
  permissions = [
    "cloudscheduler.jobs.create",
    "cloudscheduler.jobs.run",
    "cloudscheduler.jobs.get",
    "cloudscheduler.jobs.list",
    "cloudscheduler.jobs.delete",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc25_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc25_scheduler.id
  member  = "serviceAccount:${google_service_account.privesc25_scheduler.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc25_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc25_scheduler.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc25_impersonate" {
  service_account_id = google_service_account.privesc25_scheduler.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
