# Privesc Path 15: Update Existing Cloud Function
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

resource "google_service_account" "privesc15_update_function" {
  account_id   = "${var.resource_prefix}15-update-function"
  display_name = "Privesc15 - Update Function"
  description  = "Can escalate via Cloud Function code modification"
  project      = var.project_id
}

# Custom role with function update permission
resource "google_project_iam_custom_role" "update_function" {
  role_id     = "${var.resource_prefix}_updateFunction"
  title       = "Privesc - Update Cloud Function"
  description = "Vulnerable: Can update Cloud Function code"
  permissions = [
    "cloudfunctions.functions.list",
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.update",
    "cloudfunctions.functions.sourceCodeSet",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc15_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.update_function.id
  member  = "serviceAccount:${google_service_account.privesc15_update_function.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc15_impersonate" {
  service_account_id = google_service_account.privesc15_update_function.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
