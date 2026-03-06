# GCP Dataflow Module - Target Streaming Job for Privesc32
#
# This module creates a streaming Dataflow job running with a high-privilege
# service account. The job can be hijacked via dataflow.jobs.updateContents
# and dataflow.jobs.cancel for privilege escalation.
#
# ============================================================================
# COST WARNING
# ============================================================================
# This creates a Dataflow streaming job which costs ~$0.05-0.10/hr while
# running. Delete immediately after testing:
#   gcloud dataflow jobs cancel <JOB_ID> --region=us-central1
# ============================================================================

# =============================================================================
# STAGING BUCKET: Required by Dataflow for temp/staging files
# =============================================================================

resource "google_storage_bucket" "dataflow_staging" {
  name          = "${var.project_id}-${var.resource_prefix}32-dataflow-staging"
  project       = var.project_id
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
}

# =============================================================================
# TARGET INFRASTRUCTURE: Streaming Dataflow job to hijack
# =============================================================================

resource "google_dataflow_job" "privesc32_target" {
  name              = "${var.resource_prefix}32-target-streaming"
  project           = var.project_id
  region            = var.region
  template_gcs_path = "gs://dataflow-templates/latest/PubSub_to_BigQuery"
  temp_gcs_location = "${google_storage_bucket.dataflow_staging.url}/temp"

  service_account_email = var.high_priv_sa_email

  parameters = {
    inputTopic       = "projects/${var.project_id}/topics/${var.resource_prefix}-target-topic"
    outputTableSpec  = "${var.project_id}:placeholder_dataset.placeholder_table"
  }

  on_delete = "cancel"

  # Streaming jobs run continuously
  lifecycle {
    ignore_changes = [
      # Dataflow modifies these after creation
      parameters,
      labels,
    ]
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "target_job_name" {
  description = "Name of the target streaming Dataflow job for privesc32"
  value       = google_dataflow_job.privesc32_target.name
}

output "target_job_id" {
  description = "ID of the target streaming Dataflow job"
  value       = google_dataflow_job.privesc32_target.job_id
}

output "staging_bucket" {
  description = "Staging bucket for the Dataflow job"
  value       = google_storage_bucket.dataflow_staging.name
}
