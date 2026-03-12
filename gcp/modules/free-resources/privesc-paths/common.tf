# GCP Privesc Paths Module - Common Resources
#
# This file contains shared resources used across multiple privilege escalation paths.

# =============================================================================
# RATE LIMITING - Prevent hitting GCP's "service accounts per minute" quota
# =============================================================================
# GCP limits service account creation to ~5-10 per minute per project.
# We create batches with delays to avoid hitting this limit.
# Each privesc path depends on a batch delay to serialize creation.
#
# Batch Schedule (46 privesc scenarios + 3 common SAs = 49 SAs total):
#   batch1: high_priv, medium_priv, iam_viewer (3 SAs)
#   batch2: privesc1-5 (5 SAs) - IAM Service Account part 1
#   batch3: privesc6-9 (4 SAs) - IAM Service Account part 2
#   batch4: privesc10-14, lateral7, privesc15-16 (8 SAs) - Compute + Cloud Functions
#   batch5: privesc17-21 (5 SAs) - Cloud Run + Cloud Build
#   batch6: privesc22-26 (5 SAs) - Storage + Secret Manager + Pub/Sub
#   batch7: privesc27-31 (5 SAs) - Scheduler + Deploy Mgr + Composer + Dataflow Create + Dataflow Update
#   batch8: privesc32-36 (5 SAs) - Dataproc Clusters + Dataproc Jobs + GKE + Vertex AI
#   batch9: privesc37-40 (up to 4 SAs) - Notebooks Update + AI Platform + Workflows Create + Workflows Update
#   batch10: privesc41-45 (up to 5 SAs) - Eventarc Create + Eventarc Update + Workload Identity Create + Workload Identity Update + Org Policy
#   batch11: privesc46 (2 SAs) - Deny Bypass

resource "time_sleep" "batch1_delay" {
  create_duration = "0s" # First batch starts immediately
}

resource "time_sleep" "batch2_delay" {
  depends_on      = [time_sleep.batch1_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch3_delay" {
  depends_on      = [time_sleep.batch2_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch4_delay" {
  depends_on      = [time_sleep.batch3_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch5_delay" {
  depends_on      = [time_sleep.batch4_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch6_delay" {
  depends_on      = [time_sleep.batch5_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch7_delay" {
  depends_on      = [time_sleep.batch6_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch8_delay" {
  depends_on      = [time_sleep.batch7_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch9_delay" {
  depends_on      = [time_sleep.batch8_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch10_delay" {
  depends_on      = [time_sleep.batch9_delay]
  create_duration = "65s"
}

resource "time_sleep" "batch11_delay" {
  depends_on      = [time_sleep.batch10_delay]
  create_duration = "65s"
}

# =============================================================================
# HIGH-PRIVILEGE TARGET SERVICE ACCOUNT
# =============================================================================
# This is the "crown jewel" - the target of privilege escalation.
# It has Owner access to the project.

resource "google_service_account" "high_priv" {
  account_id   = "${var.resource_prefix}-high-priv-sa"
  display_name = "High Privilege Service Account"
  description  = "Target service account for privilege escalation - has Owner role"
  project      = var.project_id

  depends_on = [time_sleep.batch1_delay]
}

# Grant the high-privilege SA the Owner role
resource "google_project_iam_member" "high_priv_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.high_priv.email}"
}

# =============================================================================
# MEDIUM-PRIVILEGE SERVICE ACCOUNT (for Path 7 - Implicit Delegation)
# =============================================================================
# Used as intermediate hop in the delegation chain for privesc path 7

resource "google_service_account" "medium_priv" {
  account_id   = "${var.resource_prefix}07-medium-priv-sa"
  display_name = "Privesc07 - Medium Privilege SA"
  description  = "Intermediate SA for path 7 implicit delegation chain"
  project      = var.project_id

  depends_on = [time_sleep.batch1_delay]
}

# Grant Editor role (can do most things except IAM)
resource "google_project_iam_member" "medium_priv_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.medium_priv.email}"
}

# =============================================================================
# IAM VIEWER SERVICE ACCOUNT (Enumeration / Reconnaissance)
# =============================================================================
# This SA has Viewer role on the project, allowing read-only enumeration of
# all resources. Use it to simulate an attacker's initial reconnaissance phase
# before exploiting a specific privesc path. Works with gcloud, CloudFox,
# and other enumeration tools.

resource "google_service_account" "iam_viewer" {
  account_id   = "iam-vulnerable-viewer"
  display_name = "IAM Viewer - Enumeration SA"
  description  = "Read-only Viewer role for enumerating project resources and identifying privesc paths"
  project      = var.project_id

  depends_on = [time_sleep.batch1_delay]
}

# Grant Viewer role (read-only access to all project resources)
resource "google_project_iam_member" "iam_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.iam_viewer.email}"
}

# Allow the attacker to impersonate the viewer SA
resource "google_service_account_iam_member" "iam_viewer_impersonate" {
  service_account_id = google_service_account.iam_viewer.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# =============================================================================
# ENABLE REQUIRED APIS
# =============================================================================
# Some privilege escalation paths require specific APIs to be enabled

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudresourcemanager" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudscheduler" {
  project = var.project_id
  service = "cloudscheduler.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "deploymentmanager" {
  project = var.project_id
  service = "deploymentmanager.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "composer" {
  project = var.project_id
  service = "composer.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "dataflow" {
  project = var.project_id
  service = "dataflow.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "dataproc" {
  project = var.project_id
  service = "dataproc.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "container" {
  project = var.project_id
  service = "container.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "notebooks" {
  project = var.project_id
  service = "notebooks.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "aiplatform" {
  project = var.project_id
  service = "aiplatform.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "workflows" {
  project = var.project_id
  service = "workflows.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "eventarc" {
  project = var.project_id
  service = "eventarc.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "bigquery" {
  project = var.project_id
  service = "bigquery.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "iamcredentials" {
  project = var.project_id
  service = "iamcredentials.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "sts" {
  project = var.project_id
  service = "sts.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "orgpolicy" {
  project = var.project_id
  service = "orgpolicy.googleapis.com"

  disable_on_destroy = false
}

# =============================================================================
# SSH USER - Project-level SSH access for the attacker
# =============================================================================
# Grants the attacker identity project-level permissions to SSH into any
# compute instance. This separates "SSH access" from "privilege escalation"
# so privesc paths only need the vulnerable permissions, not SSH plumbing.
# Used as the completion step for compute-based paths (10, 15, 15b, 15c).

resource "google_project_iam_custom_role" "ssh_user" {
  role_id     = "${var.resource_prefix}_ssh_user"
  title       = "Privesc SSH User"
  description = "Project-level SSH access for completing compute-based privesc paths"
  project     = var.project_id

  permissions = [
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.setMetadata",
    "compute.projects.get",
    "compute.zones.list",
  ]
}

resource "google_project_iam_member" "ssh_user" {
  project = var.project_id
  role    = google_project_iam_custom_role.ssh_user.id
  member  = var.attacker_member
}

# =============================================================================
# SHARED CUSTOM ROLE: actAs only (no extra permissions)
# =============================================================================
# Many privesc paths need iam.serviceAccounts.actAs on a specific SA.
# Using roles/iam.serviceAccountUser adds unnecessary permissions (get, list).
# This custom role + IAM conditions scopes actAs to only the target SA.

resource "google_project_iam_custom_role" "actas_only" {
  role_id     = "${var.resource_prefix}_actAs_only"
  title       = "actAs Only"
  description = "Grants only iam.serviceAccounts.actAs - use with IAM conditions to scope to specific SAs"
  project     = var.project_id

  permissions = [
    "iam.serviceAccounts.actAs",
  ]
}

# =============================================================================
# TARGET RESOURCES FOR RESOURCE-LEVEL PRIVESC PATHS
# =============================================================================
# These resources are targets for privesc paths that use resource-level IAM.
# Creating specific targets prevents alternative attack paths.

# Target bucket for privesc22 (bucket setIamPolicy) and privesc23 (storage write)
resource "google_storage_bucket" "target_bucket" {
  name          = "${var.project_id}-${var.resource_prefix}-target"
  project       = var.project_id
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true

  depends_on = [google_project_service.storage]
}

# Target secret for privesc24 (secret access) and privesc25 (secret setIamPolicy)
resource "google_secret_manager_secret" "target_secret" {
  secret_id = "${var.resource_prefix}-target-secret"
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [google_project_service.secretmanager]
}

# Add a secret version with dummy data
resource "google_secret_manager_secret_version" "target_secret_version" {
  secret      = google_secret_manager_secret.target_secret.id
  secret_data = "SENSITIVE_API_KEY_12345"
}

# Target Pub/Sub topic for privesc26 (pubsub setIamPolicy)
resource "google_pubsub_topic" "target_topic" {
  name    = "${var.resource_prefix}-target-topic"
  project = var.project_id

  depends_on = [google_project_service.pubsub]
}

# Target Pub/Sub subscription for privesc26
resource "google_pubsub_subscription" "target_subscription" {
  name    = "${var.resource_prefix}-target-sub"
  project = var.project_id
  topic   = google_pubsub_topic.target_topic.id
}

# Target BigQuery dataset for privesc39 (bigquery setIamPolicy)
resource "google_bigquery_dataset" "target_dataset" {
  dataset_id = replace("${var.resource_prefix}_target_dataset", "-", "_")
  project    = var.project_id
  location   = "US"

  delete_contents_on_destroy = true

  depends_on = [google_project_service.bigquery]
}
