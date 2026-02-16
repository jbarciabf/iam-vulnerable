# Privesc Path 18: Update Existing Cloud Function
#
# VULNERABILITY: A service account with cloudfunctions.functions.update can
# modify the code of an existing function that runs with a high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find Cloud Functions running as high-priv service accounts
#   3. Update the function's source code to execute malicious logic
#   4. Trigger the function to run your code with high-priv SA permissions
#
# DETECTION: FoxMapper detects this via the updateFunction edge checker
#
# REAL-WORLD IMPACT: Critical - Code injection into privileged functions
#
# DISABLED BY DEFAULT: Requires enable_privesc18 = true (creates target function, free when idle)

resource "google_service_account" "privesc18_update_function" {
  count = var.enable_privesc18 ? 1 : 0

  account_id   = "${var.resource_prefix}18-update-function"
  display_name = "Privesc18 - Update Function"
  description  = "Can escalate via Cloud Function code modification"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with function update permission and minimum required supporting permissions
resource "google_project_iam_custom_role" "update_function" {
  count = var.enable_privesc18 ? 1 : 0

  role_id     = "${var.resource_prefix}_18_updateFunction"
  title       = "Privesc18 - Update Cloud Function"
  description = "Vulnerable: Can update Cloud Function code"
  permissions = [
    # Primary vulnerable permission
    "cloudfunctions.functions.update",
    # Minimum required for update to succeed
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.generateUploadUrl",
    "cloudfunctions.operations.get",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc18_role" {
  count = var.enable_privesc18 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.update_function[0].id
  member  = "serviceAccount:${google_service_account.privesc18_update_function[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc18_impersonate" {
  count = var.enable_privesc18 ? 1 : 0

  service_account_id = google_service_account.privesc18_update_function[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on the high-privilege SA (required even for code-only updates)
# GCP requires actAs on the function's runtime SA to update it
resource "google_service_account_iam_member" "privesc18_actas_high_priv" {
  count = var.enable_privesc18 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc18_update_function[0].email}"
}

# Grant actAs on default Compute SA (required for Cloud Build)
resource "google_service_account_iam_member" "privesc18_actas_default_compute" {
  count = var.enable_privesc18 ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc18_update_function[0].email}"
}
