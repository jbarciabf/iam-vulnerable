# Privesc Path 24: Storage Objects Create (Sensitive Bucket Write)
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

resource "google_service_account" "privesc24_storage_write" {
  account_id   = "${var.resource_prefix}24-storage-write"
  display_name = "Privesc24 - storage.objects.create"
  description  = "Can escalate via storage.objects.create on sensitive buckets"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Create a custom role with storage write permissions
resource "google_project_iam_custom_role" "privesc24_storage_write" {
  role_id     = "${var.resource_prefix}_24_storage_write"
  title       = "Privesc24 Storage Object Writer"
  description = "Can write objects to storage buckets"
  project     = var.project_id

  permissions = [
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "storage.buckets.get",
    "storage.buckets.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc24_storage_write" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc24_storage_write.id
  member  = "serviceAccount:${google_service_account.privesc24_storage_write.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc24_impersonate" {
  service_account_id = google_service_account.privesc24_storage_write.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
