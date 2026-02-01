# Privesc Path 15: actAs + Cloud Function Deployment
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

resource "google_service_account" "privesc15_actas_function" {
  account_id   = "${var.resource_prefix}5-actas-function"
  display_name = "Privesc5 - actAs + Cloud Function"
  description  = "Can escalate via Cloud Function with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc15_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc15_actas_function.email}"
}

# Grant Cloud Functions developer permissions
resource "google_project_iam_member" "privesc15_functions" {
  project = var.project_id
  role    = "roles/cloudfunctions.developer"
  member  = "serviceAccount:${google_service_account.privesc15_actas_function.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc15_impersonate" {
  service_account_id = google_service_account.privesc15_actas_function.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
