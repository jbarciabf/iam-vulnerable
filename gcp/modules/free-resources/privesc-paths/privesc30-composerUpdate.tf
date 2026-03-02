# Privesc Path 30: Cloud Composer Update (Hijack Existing Environment)
#
# VULNERABILITY: A service account with composer.environments.update and storage
# write permissions can upload malicious DAGs to an existing Composer environment,
# executing code with the environment's service account permissions.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find an existing Composer environment with a high-priv SA
#   3. Get the environment's DAGs bucket
#   4. Upload a malicious DAG that exfiltrates the SA token
#   5. The DAG executes with the environment's SA credentials
#
# NOTE: Unlike Path 29, this does NOT require composer.environments.create.
#       The service account cannot be changed after environment creation,
#       so this path hijacks an EXISTING environment's SA.
#
# DETECTION: FoxMapper detects this via the composer edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack existing workflow orchestration
#
# ============================================================================
# ⚠️  EXTREME COST WARNING ⚠️
# ============================================================================
# The target infrastructure for this path (Composer environment) costs ~$400/month
# (~$13/day) even when idle. Only enable this path if you specifically need
# to test composer.environments.update privilege escalation.
#
# DISABLED BY DEFAULT: Set enable_privesc30 = true to enable
#
# TARGET INFRASTRUCTURE: Created by modules/non-free-resources/composer
#
# DELETE IMMEDIATELY after testing:
#   gcloud composer environments delete privesc30-target --location=us-central1 --quiet
# ============================================================================

resource "google_service_account" "privesc30_composer_update" {
  count = var.enable_privesc30 ? 1 : 0

  account_id   = "${var.resource_prefix}30-composer-update"
  display_name = "Privesc30 - Composer Update"
  description  = "Can escalate via composer.environments.update (no create needed)"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with UPDATE but NO CREATE
resource "google_project_iam_custom_role" "privesc30_composer_update" {
  count = var.enable_privesc30 ? 1 : 0

  role_id     = "${var.resource_prefix}_30_composer_update"
  title       = "Privesc30 - Composer Update Only"
  description = "Vulnerable: Can update (but NOT create) Composer environments and upload DAGs"
  permissions = [
    # Composer permissions - UPDATE only, no CREATE
    "composer.environments.update",
    "composer.environments.get",
    "composer.environments.list",
    # Storage permissions (required to upload DAGs to environment bucket)
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc30_role" {
  count = var.enable_privesc30 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc30_composer_update[0].id
  member  = "serviceAccount:${google_service_account.privesc30_composer_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc30_impersonate" {
  count = var.enable_privesc30 ? 1 : 0

  service_account_id = google_service_account.privesc30_composer_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
