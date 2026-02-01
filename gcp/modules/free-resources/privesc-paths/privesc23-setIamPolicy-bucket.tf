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
  account_id   = "${var.resource_prefix}14-bucket-iam"
  display_name = "Privesc14 - Bucket IAM"
  description  = "Can escalate via storage bucket IAM modification"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Custom role with bucket IAM manipulation
resource "google_project_iam_custom_role" "bucket_iam" {
  role_id     = "${var.resource_prefix}_bucketIam"
  title       = "Privesc - Bucket IAM"
  description = "Vulnerable: Can modify storage bucket IAM policies"
  permissions = [
    "storage.buckets.list",
    "storage.buckets.get",
    "storage.buckets.getIamPolicy",
    "storage.buckets.setIamPolicy",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc23_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.bucket_iam.id
  member  = "serviceAccount:${google_service_account.privesc23_bucket_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc23_impersonate" {
  service_account_id = google_service_account.privesc23_bucket_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
