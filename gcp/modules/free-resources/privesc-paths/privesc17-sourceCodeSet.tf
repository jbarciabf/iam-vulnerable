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
#
# DISABLED BY DEFAULT: Requires enable_privesc17 = true (creates target function, free when idle)

resource "google_service_account" "privesc17_source_code_set" {
  count = var.enable_privesc17 ? 1 : 0

  account_id   = "${var.resource_prefix}17-sourcecode-set"
  display_name = "Privesc17 - sourceCodeSet"
  description  = "Can escalate via cloudfunctions.functions.sourceCodeSet"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Create a custom role with ONLY sourceCodeSet permission
# Removed: list/get (discovery) and storage.* (should use privesc24 for storage write)
# This focuses the attack path on sourceCodeSet only
resource "google_project_iam_custom_role" "privesc17_source_code_set" {
  count = var.enable_privesc17 ? 1 : 0

  role_id     = "${var.resource_prefix}_17_source_code_set"
  title       = "Privesc17 Source Code Set"
  description = "Can set function source code (sourceCodeSet only)"
  project     = var.project_id

  permissions = [
    "cloudfunctions.functions.sourceCodeSet",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc17_source_code_set" {
  count = var.enable_privesc17 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc17_source_code_set[0].id
  member  = "serviceAccount:${google_service_account.privesc17_source_code_set[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc17_impersonate" {
  count = var.enable_privesc17 ? 1 : 0

  service_account_id = google_service_account.privesc17_source_code_set[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
