# Privesc Path 29: Cloud Composer (Airflow) Environment
#
# VULNERABILITY: A service account with composer.environments.create, actAs,
# and storage write permissions can create Composer environments running with
# high-priv SAs and upload malicious DAGs.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Create a Cloud Composer environment with high-priv SA
#   3. Upload a malicious DAG to the environment's GCS bucket
#   4. The DAG executes with the high-priv SA's credentials
#   5. Extract token via metadata server from within the DAG
#
# DETECTION: FoxMapper detects this via the composer edge checker
#
# REAL-WORLD IMPACT: Critical - Workflow orchestration abuse
#
# NOTE: DAGs can ONLY be loaded from the environment's GCS bucket.
#       There is no way to point Composer at a GitHub repo or external bucket.
#       The attacker must have storage.objects.create on the DAGs bucket.
#       Since the attacker creates the environment, they typically get bucket
#       access via the same permissions that allow environment creation.
#
# COST: ~$300/month (Composer environments are expensive)

resource "google_service_account" "privesc29_composer" {
  account_id   = "${var.resource_prefix}29-composer"
  display_name = "Privesc29 - Cloud Composer"
  description  = "Can escalate via Cloud Composer environment"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Custom role with Composer permissions + Storage write for DAG uploads
resource "google_project_iam_custom_role" "privesc29_composer" {
  role_id     = "${var.resource_prefix}_29_composer"
  title       = "Privesc29 - Cloud Composer"
  description = "Vulnerable: Can create Composer environments and upload DAGs"
  permissions = [
    # Composer permissions
    "composer.environments.create",
    "composer.environments.get",
    "composer.environments.list",
    "composer.environments.update",
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
resource "google_project_iam_member" "privesc29_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc29_composer.id
  member  = "serviceAccount:${google_service_account.privesc29_composer.email}"
}

# Grant actAs on the high-privilege service account
resource "google_service_account_iam_member" "privesc29_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc29_composer.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc29_impersonate" {
  service_account_id = google_service_account.privesc29_composer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
