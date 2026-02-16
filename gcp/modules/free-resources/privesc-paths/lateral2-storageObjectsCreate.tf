# Lateral Movement Path 2: Storage Objects Create (Sensitive Bucket Write)
#
# CATEGORY: Persistence / Injection (NOT privilege escalation)
#
# VULNERABILITY: A service account with storage.objects.create on a sensitive
# bucket (e.g., Cloud Function source, Terraform state, config buckets) can
# write malicious content that gets executed or processed by other services.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Write malicious code to a Cloud Function source bucket
#   3. Or write to a startup script bucket used by VMs
#   4. When the service uses the bucket content, malicious code executes
#
# DETECTION: FoxMapper detects this via the storageObjectsCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Indirect code execution via bucket poisoning

resource "google_service_account" "lateral2_storage_write" {
  account_id   = "lateral2-storage-write"
  display_name = "Lateral2 - storage.objects.create"
  description  = "Can inject content via storage.objects.create on sensitive buckets"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant object create ONLY on the target bucket (not project-wide)
# This prevents the attacker from writing to other buckets
resource "google_storage_bucket_iam_member" "lateral2_object_creator" {
  bucket = google_storage_bucket.target_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.lateral2_storage_write.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "lateral2_impersonate" {
  service_account_id = google_service_account.lateral2_storage_write.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
