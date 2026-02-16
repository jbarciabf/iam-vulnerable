# Privesc Path 29: Cloud Composer (Airflow) Environment
#
# VULNERABILITY: A service account with composer.environments.create and actAs
# can create Composer environments running with high-priv SAs.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Cloud Composer environment with high-priv SA
#   3. Access the Airflow UI or DAGs bucket
#   4. Deploy a DAG that runs with high-priv SA permissions
#
# DETECTION: FoxMapper detects this via the composer edge checker
#
# REAL-WORLD IMPACT: Critical - Workflow orchestration abuse

resource "google_service_account" "privesc29_composer" {
  account_id   = "${var.resource_prefix}29-composer"
  display_name = "Privesc29 - Cloud Composer"
  description  = "Can escalate via Cloud Composer environment"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with Composer permissions
resource "google_project_iam_custom_role" "privesc29_composer" {
  role_id     = "${var.resource_prefix}_29_composer"
  title       = "Privesc29 - Cloud Composer"
  description = "Vulnerable: Can create/update Composer environments"
  permissions = [
    "composer.environments.create",
    "composer.environments.get",
    "composer.environments.list",
    "composer.environments.update",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc29_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc29_composer.id
  member  = "serviceAccount:${google_service_account.privesc29_composer.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc29_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc29_composer.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc29_impersonate" {
  service_account_id = google_service_account.privesc29_composer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
