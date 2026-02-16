# Privesc Path 36: AI Platform Custom Jobs
#
# VULNERABILITY: A service account with aiplatform.customJobs.create and actAs
# can create Vertex AI custom training jobs that run with a high-privilege
# service account.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a custom training job with a privileged SA
#   3. The job executes your container/code
#   4. Access the SA token from within the job
#   5. Make privileged API calls
#
# DETECTION: FoxMapper detects this via the aiplatformCustomJobs edge checker
#
# REAL-WORLD IMPACT: Critical - Arbitrary code execution as privileged SA
#
# NOTE: Creating AI Platform jobs incurs cost
#       This path only creates the IAM configuration

resource "google_service_account" "privesc36_aiplatform" {
  account_id   = "${var.resource_prefix}36-aiplatform"
  display_name = "Privesc36 - aiplatform.customJobs.create"
  description  = "Can escalate via AI Platform custom jobs"
  project      = var.project_id

  depends_on = [time_sleep.batch8_delay]
}

# Create a custom role with AI Platform job permissions
resource "google_project_iam_custom_role" "privesc36_aiplatform" {
  role_id     = "${var.resource_prefix}_36_aiplatform"
  title       = "Privesc36 AI Platform Job Creator"
  description = "Can create AI Platform custom jobs"
  project     = var.project_id

  permissions = [
    "aiplatform.customJobs.create",
    "aiplatform.customJobs.get",
    "aiplatform.customJobs.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc36_aiplatform" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc36_aiplatform.id
  member  = "serviceAccount:${google_service_account.privesc36_aiplatform.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc36_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc36_aiplatform.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc36_impersonate" {
  service_account_id = google_service_account.privesc36_aiplatform.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
