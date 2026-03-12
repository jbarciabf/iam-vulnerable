# Privesc Path 25: Cloud Scheduler Update (Hijack Existing Job)
#
# VULNERABILITY: A service account with cloudscheduler.jobs.update and actAs
# can modify existing scheduled jobs to use a different service account or
# redirect to an attacker-controlled endpoint.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find an existing Cloud Scheduler job
#   3. Update it to point to attacker's endpoint with high-priv SA
#   4. Trigger the job to capture the OIDC token
#
# DETECTION: FoxMapper detects this via scheduler edge checker
#
# REAL-WORLD IMPACT: High - Hijack existing scheduled tasks, token theft
#
# NOTE: This path is DISABLED by default because it requires an existing
#       Cloud Scheduler job to hijack. Enable with: enable_privesc25 = true
#
# TARGET INFRASTRUCTURE: Created by modules/non-free-resources/cloud-scheduler

resource "google_service_account" "privesc25_scheduler_update" {
  count = var.enable_privesc25 ? 1 : 0

  account_id   = "${var.resource_prefix}25-scheduler-update"
  display_name = "Privesc25 - Cloud Scheduler Update"
  description  = "Can escalate via cloudscheduler.jobs.update (hijack existing jobs)"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with Scheduler update permissions (NO create)
resource "google_project_iam_custom_role" "privesc25_scheduler_update" {
  count = var.enable_privesc25 ? 1 : 0

  role_id     = "${var.resource_prefix}_25_scheduler_update"
  title       = "Privesc25 - Cloud Scheduler Update"
  description = "Vulnerable: Can update (but not create) Cloud Scheduler jobs"
  permissions = [
    "cloudscheduler.jobs.update",
    "cloudscheduler.jobs.run",
    "cloudscheduler.jobs.get",
    "cloudscheduler.jobs.list",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc25_role" {
  count = var.enable_privesc25 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc25_scheduler_update[0].id
  member  = "serviceAccount:${google_service_account.privesc25_scheduler_update[0].email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc25_actas" {
  count = var.enable_privesc25 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc25_scheduler_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc25_impersonate" {
  count = var.enable_privesc25 ? 1 : 0

  service_account_id = google_service_account.privesc25_scheduler_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
