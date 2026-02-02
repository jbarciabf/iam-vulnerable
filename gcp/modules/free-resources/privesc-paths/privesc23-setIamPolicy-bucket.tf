# Privesc Path 23: setIamPolicy on Storage Bucket
#
# VULNERABILITY: A service account with storage.buckets.setIamPolicy can modify
# bucket permissions to access sensitive data or Terraform state.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find buckets (especially Terraform state buckets)
#   3. Grant yourself storage.objectViewer on the bucket
#   4. Read sensitive data or credentials from stored objects
#
# DETECTION: FoxMapper detects this via the storage setIamPolicy edge checker
#
# REAL-WORLD IMPACT: High - Data exfiltration, Terraform state access

resource "google_service_account" "privesc23_bucket_iam" {
  account_id   = "${var.resource_prefix}23-bucket-iam"
  display_name = "Privesc23 - Bucket IAM"
  description  = "Can escalate via storage bucket IAM modification"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant setIamPolicy ONLY on the target bucket (not project-wide)
# This prevents the attacker from modifying IAM on other buckets
resource "google_storage_bucket_iam_member" "privesc23_bucket_admin" {
  bucket = google_storage_bucket.target_bucket.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${google_service_account.privesc23_bucket_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc23_impersonate" {
  service_account_id = google_service_account.privesc23_bucket_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
