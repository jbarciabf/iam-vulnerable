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
# Batch Schedule (43 privesc scenarios + 2 common SAs = 45 SAs total):
#   batch1: high_priv, medium_priv (2 SAs)
#   batch2: privesc1-5 (5 SAs) - IAM Service Account part 1
#   batch3: privesc6-9 (4 SAs) - IAM Service Account part 2
#   batch4: privesc10-14, privesc15-17 (8 SAs) - Compute + Cloud Functions
#   batch5: privesc18-22 (5 SAs) - Cloud Run + Cloud Build
#   batch6: privesc23-27 (5 SAs) - Storage + Secret Manager + Pub/Sub
#   batch7: privesc28-32 (5 SAs) - Scheduler + Deploy Mgr + Composer + Dataflow + Dataproc
#   batch8: privesc33-37 (5 SAs) - Dataproc Jobs + GKE + Vertex AI
#   batch9: privesc38-42 (5 SAs) - Workflows + Eventarc + BigQuery + Workload Identity + Org Policy
#   batch10: privesc43 (1 SA) - Deny Bypass

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
# MEDIUM-PRIVILEGE SERVICE ACCOUNT
# =============================================================================
# Used for certain escalation paths that require intermediate privileges

resource "google_service_account" "medium_priv" {
  account_id   = "${var.resource_prefix}-medium-priv-sa"
  display_name = "Medium Privilege Service Account"
  description  = "Intermediate privilege service account for escalation chains"
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

resource "google_project_service" "orgpolicy" {
  project = var.project_id
  service = "orgpolicy.googleapis.com"

  disable_on_destroy = false
}
