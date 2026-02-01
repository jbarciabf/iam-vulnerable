# Privesc Path 17: Cloud Functions sourceCodeSet
#
# VULNERABILITY: A service account with cloudfunctions.functions.sourceCodeSet
# can update the source code of an existing function without needing the full
# update permission, allowing code injection.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Upload malicious code to a bucket
#   3. Use sourceCodeSet to point the function to the malicious code
#   4. Invoke the function to execute as the function's service account
#
# DETECTION: FoxMapper detects this via the sourceCodeSet edge checker
#
# REAL-WORLD IMPACT: Critical - Code execution as the function's SA

resource "google_service_account" "privesc17_source_code_set" {
  account_id   = "${var.resource_prefix}17-sourcecode-set"
  display_name = "Privesc17 - sourceCodeSet"
  description  = "Can escalate via cloudfunctions.functions.sourceCodeSet"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Create a custom role with sourceCodeSet permission
resource "google_project_iam_custom_role" "privesc17_source_code_set" {
  role_id     = "${var.resource_prefix}_17_source_code_set"
  title       = "Privesc17 Source Code Set"
  description = "Can set function source code"
  project     = var.project_id

  permissions = [
    "cloudfunctions.functions.sourceCodeSet",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.list",
    "storage.objects.create",
    "storage.objects.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc17_source_code_set" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc17_source_code_set.id
  member  = "serviceAccount:${google_service_account.privesc17_source_code_set.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc17_impersonate" {
  service_account_id = google_service_account.privesc17_source_code_set.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
