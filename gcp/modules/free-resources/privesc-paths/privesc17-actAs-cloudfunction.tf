# Privesc Path 17: actAs + Cloud Function Deployment
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus cloudfunctions.functions.create can deploy a function running as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Deploy a Cloud Function that runs as the high-priv SA
#   3. The function code can access GCP APIs as the high-priv SA
#   4. Invoke the function to execute privileged operations
#
# DETECTION: FoxMapper detects this via the actAs + cloudfunctions edge checker
#
# REAL-WORLD IMPACT: Critical - Serverless privilege escalation
#
# NOTE: Gen2 functions use Cloud Build, requiring actAs on the default Compute SA

resource "google_service_account" "privesc17_actas_function" {
  account_id   = "${var.resource_prefix}17-actas-function"
  display_name = "Privesc17 - actAs + Cloud Function"
  description  = "Can escalate via Cloud Function with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc17_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc17_actas_function.email}"
}

# Custom role with minimal Cloud Functions permissions
resource "google_project_iam_custom_role" "privesc17_functions" {
  role_id     = "${var.resource_prefix}_17_cloudfunctions"
  title       = "Privesc17 - Cloud Functions Deploy"
  description = "Minimal permissions for Cloud Functions deployment with SA"
  project     = var.project_id

  permissions = [
    # Primary vulnerable permissions
    "cloudfunctions.functions.create",
    # Minimum required for deployment to succeed
    "cloudfunctions.functions.get",
    "cloudfunctions.functions.generateUploadUrl", # Upload source code
    "cloudfunctions.operations.get",
    # Gen2 functions require Cloud Run permissions
    "run.services.getIamPolicy",
    "run.services.setIamPolicy", # Required for --allow-unauthenticated
  ]
}

# Grant Cloud Functions permissions
resource "google_project_iam_member" "privesc17_functions" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc17_functions.id
  member  = "serviceAccount:${google_service_account.privesc17_actas_function.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc17_impersonate" {
  service_account_id = google_service_account.privesc17_actas_function.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on default Compute SA (required for Cloud Functions Gen2 deployment)
# Cloud Functions Gen2 uses Cloud Build which needs actAs on the default Compute SA
resource "google_service_account_iam_member" "privesc17_actas_default_compute" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.project_number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc17_actas_function.email}"
}
