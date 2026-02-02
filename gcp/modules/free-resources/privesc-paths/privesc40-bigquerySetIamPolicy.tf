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

# Grant admin ONLY on the target dataset (not project-wide)
# This prevents the attacker from modifying IAM on other datasets
resource "google_bigquery_dataset_iam_member" "privesc40_dataset_admin" {
  dataset_id = google_bigquery_dataset.target_dataset.dataset_id
  role       = "roles/bigquery.admin"
  member     = "serviceAccount:${google_service_account.privesc40_bigquery.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc40_impersonate" {
  service_account_id = google_service_account.privesc40_bigquery.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
