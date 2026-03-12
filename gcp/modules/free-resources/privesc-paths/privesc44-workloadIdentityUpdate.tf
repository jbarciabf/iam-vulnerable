# Privesc Path 44: Workload Identity Federation Update (Hijack Existing Provider)
#
# VULNERABILITY: A service account with iam.workloadIdentityPoolProviders.update
# can modify an existing Workload Identity Pool Provider to change the issuer
# URI and attribute mappings, allowing an attacker-controlled IdP to federate
# into GCP.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List Workload Identity Pools and Providers
#   3. Update a provider's issuer URI to point to an attacker-controlled IdP
#   4. Modify attribute mappings to match attacker tokens
#   5. Generate a token from the attacker IdP
#   6. Exchange for GCP credentials using STS
#
# DETECTION: FoxMapper detects this via the workloadIdentityUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack federated identity for GCP access
#
# NOTE: This path is DISABLED by default (enable_privesc44 = false)
#       Enable with: enable_privesc44 = true

resource "google_service_account" "privesc44_workload_identity_update" {
  count = var.enable_privesc44 ? 1 : 0

  account_id   = "${var.resource_prefix}44-wid-update"
  display_name = "Privesc44 - Workload Identity Update"
  description  = "Can escalate via Workload Identity Pool Provider update"
  project      = var.project_id

  depends_on = [time_sleep.batch10_delay]
}

# Custom role with Workload Identity update permissions
resource "google_project_iam_custom_role" "privesc44_workload_identity_update" {
  count = var.enable_privesc44 ? 1 : 0

  role_id     = "${var.resource_prefix}_44_workload_identity_update"
  title       = "Privesc44 Workload Identity Updater"
  description = "Can update Workload Identity Pool Providers"
  project     = var.project_id

  permissions = [
    "iam.workloadIdentityPoolProviders.update",
    "iam.workloadIdentityPoolProviders.get",
    "iam.workloadIdentityPoolProviders.list",
    "iam.workloadIdentityPools.get",
    "iam.workloadIdentityPools.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc44_workload_identity_update" {
  count = var.enable_privesc44 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc44_workload_identity_update[0].id
  member  = "serviceAccount:${google_service_account.privesc44_workload_identity_update[0].email}"
}

# No actAs binding needed - changes issuer URI, doesn't need actAs

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc44_impersonate" {
  count = var.enable_privesc44 ? 1 : 0

  service_account_id = google_service_account.privesc44_workload_identity_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
