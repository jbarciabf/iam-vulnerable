# Privesc Path 31: Dataflow Job
#
# VULNERABILITY: A service account with dataflow.jobs.create and actAs can
# create Dataflow jobs running with a high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Dataflow job that runs with high-priv SA
#   3. The job's workers have access to the SA's permissions
#   4. The job can read secrets, modify resources, etc.
#
# DETECTION: FoxMapper detects this via the dataflow edge checker
#
# REAL-WORLD IMPACT: High - Data pipeline abuse

resource "google_service_account" "privesc31_dataflow" {
  account_id   = "${var.resource_prefix}31-dataflow"
  display_name = "Privesc31 - Dataflow"
  description  = "Can escalate via Dataflow job"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Grant Dataflow developer
resource "google_project_iam_member" "privesc31_dataflow" {
  project = var.project_id
  role    = "roles/dataflow.developer"
  member  = "serviceAccount:${google_service_account.privesc31_dataflow.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc31_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc31_dataflow.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc31_impersonate" {
  service_account_id = google_service_account.privesc31_dataflow.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
