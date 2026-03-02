# GCP Cloud Scheduler Module - Target Job for Privesc26
#
# This module creates a Cloud Scheduler job that can be hijacked via
# cloudscheduler.jobs.update for privilege escalation.
#
# COST: Minimal (pay per job execution, and this job rarely runs)

# =============================================================================
# TARGET INFRASTRUCTURE: Scheduler job to hijack
# =============================================================================

# Target scheduler job that can be hijacked
# This job runs with no service account initially - attacker will update it to use high-priv SA
resource "google_cloud_scheduler_job" "privesc26_target_job" {
  name        = "${var.resource_prefix}26-target-job"
  description = "Target job for privesc26 - hijack via cloudscheduler.jobs.update"
  region      = var.region
  project     = var.project_id
  schedule    = "0 0 1 1 *" # Once a year (Jan 1 at midnight) - not intended to run automatically

  http_target {
    uri         = "https://example.com/placeholder"
    http_method = "POST"
    body        = base64encode("{\"message\": \"This job will be hijacked\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    # Initially NO oidc_token - attacker will add one with high-priv SA
  }

  retry_config {
    retry_count = 0
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "target_job_name" {
  description = "Name of the target Cloud Scheduler job for privesc26"
  value       = google_cloud_scheduler_job.privesc26_target_job.name
}

output "target_job_region" {
  description = "Region of the target Cloud Scheduler job"
  value       = var.region
}
