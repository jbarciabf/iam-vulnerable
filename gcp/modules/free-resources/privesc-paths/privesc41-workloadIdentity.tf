# Privesc Path 41: Workload Identity Federation Abuse
#
# VULNERABILITY: A service account that can create or modify Workload Identity
# Pool Providers can configure federation to accept tokens from external
# identity providers, allowing external parties to impersonate GCP identities.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Workload Identity Pool Provider
#   3. Configure it to trust tokens from an IdP you control
#   4. Generate a token from your IdP
#   5. Exchange for GCP credentials using STS
#
# DETECTION: FoxMapper detects this via the workloadIdentity edge checker
#
# REAL-WORLD IMPACT: Critical - External authentication to GCP resources

resource "google_service_account" "privesc41_workload_identity" {
  account_id   = "${var.resource_prefix}41-workload-id"
  display_name = "Privesc41 - Workload Identity"
  description  = "Can escalate via Workload Identity Pool abuse"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Create a custom role with Workload Identity permissions
resource "google_project_iam_custom_role" "privesc41_workload_identity" {
  role_id     = "${var.resource_prefix}_41_workload_id"
  title       = "Privesc41 Workload Identity Admin"
  description = "Can manage Workload Identity Pool Providers"
  project     = var.project_id

  permissions = [
    "iam.workloadIdentityPoolProviders.create",
    "iam.workloadIdentityPoolProviders.get",
    "iam.workloadIdentityPoolProviders.list",
    "iam.workloadIdentityPools.create",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPools.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc41_workload_identity" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc41_workload_identity.id
  member  = "serviceAccount:${google_service_account.privesc41_workload_identity.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc41_impersonate" {
  service_account_id = google_service_account.privesc41_workload_identity.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
