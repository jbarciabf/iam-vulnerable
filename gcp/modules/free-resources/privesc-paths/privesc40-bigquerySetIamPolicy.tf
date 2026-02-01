# Privesc Path 40: BigQuery Datasets setIamPolicy
#
# VULNERABILITY: A service account with bigquery.datasets.setIamPolicy
# can grant itself or others access to BigQuery datasets, potentially
# exposing sensitive data or allowing data exfiltration.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List datasets in the project
#   3. Grant yourself bigquery.dataViewer on sensitive datasets
#   4. Query and exfiltrate the data
#
# DETECTION: FoxMapper detects this via the bigquerySetIamPolicy edge checker
#
# REAL-WORLD IMPACT: High - Access to potentially sensitive analytical data

resource "google_service_account" "privesc40_bigquery" {
  account_id   = "${var.resource_prefix}40-bq-setiam"
  display_name = "Privesc40 - bigquery.datasets.setIamPolicy"
  description  = "Can escalate via bigquery.datasets.setIamPolicy"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Create a custom role with BigQuery IAM permissions
resource "google_project_iam_custom_role" "privesc40_bigquery" {
  role_id     = "${var.resource_prefix}_40_bq_setiam"
  title       = "Privesc40 BigQuery Dataset IAM Admin"
  description = "Can modify IAM policies on BigQuery datasets"
  project     = var.project_id

  permissions = [
    "bigquery.datasets.setIamPolicy",
    "bigquery.datasets.getIamPolicy",
    "bigquery.datasets.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc40_bigquery" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc40_bigquery.id
  member  = "serviceAccount:${google_service_account.privesc40_bigquery.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc40_impersonate" {
  service_account_id = google_service_account.privesc40_bigquery.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
