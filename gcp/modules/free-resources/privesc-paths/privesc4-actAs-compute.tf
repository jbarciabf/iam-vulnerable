# Privesc Path 4: actAs + Compute Instance Creation
#
# VULNERABILITY: A service account with iam.serviceAccounts.actAs on a high-priv
# SA plus compute.instances.create can create a VM running as the high-priv SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Compute Engine instance with the high-priv SA attached
#   3. SSH into the instance
#   4. Use the metadata server to get tokens for the high-priv SA
#
# DETECTION: FoxMapper detects this via the actAs + compute edge checker
#
# REAL-WORLD IMPACT: Critical - Common escalation path in GCP

resource "google_service_account" "privesc4_actas_compute" {
  account_id   = "${var.resource_prefix}4-actas-compute"
  display_name = "Privesc4 - actAs + Compute"
  description  = "Can escalate via VM creation with high-priv SA"
  project      = var.project_id

  depends_on = [time_sleep.batch2_delay]
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc4_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc4_actas_compute.email}"
}

# Grant compute instance creation permissions
resource "google_project_iam_member" "privesc4_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.privesc4_actas_compute.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc4_impersonate" {
  service_account_id = google_service_account.privesc4_actas_compute.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
