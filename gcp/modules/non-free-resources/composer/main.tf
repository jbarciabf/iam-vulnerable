# GCP Composer Module - Target Environment for Privesc30
#
# This module creates a Cloud Composer environment that can be hijacked via
# composer.environments.update for privilege escalation.
#
# ============================================================================
# ⚠️  EXTREME COST WARNING ⚠️
# ============================================================================
# This creates a Composer environment which costs ~$400/month (~$13/day)
# even when idle. Only enable this if you specifically need to test
# composer.environments.update privilege escalation.
#
# DELETE IMMEDIATELY after testing:
#   gcloud composer environments delete privesc30-target --location=us-central1 --quiet
# ============================================================================

# =============================================================================
# TARGET INFRASTRUCTURE: Existing Composer environment to hijack
# =============================================================================

resource "google_composer_environment" "privesc30_target" {
  name    = "${var.resource_prefix}30-target"
  region  = "us-central1"
  project = var.project_id

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = var.high_priv_sa_email
    }

    software_config {
      image_version = "composer-3-airflow-2"
    }
  }

  # Composer environments take 15-25 minutes to create
  timeouts {
    create = "60m"
    update = "60m"
    delete = "30m"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "target_environment_name" {
  description = "Name of the target Composer environment for privesc30"
  value       = google_composer_environment.privesc30_target.name
}

output "target_environment_region" {
  description = "Region of the target Composer environment"
  value       = "us-central1"
}

output "dags_bucket" {
  description = "GCS bucket for DAGs (attacker will upload malicious DAGs here)"
  value       = google_composer_environment.privesc30_target.config[0].dag_gcs_prefix
}

# =============================================================================
# ⚠️  REMINDER: DELETE THIS ENVIRONMENT AFTER TESTING!
# =============================================================================
# Run: gcloud composer environments delete privesc30-target --location=us-central1 --quiet
# Or: terraform destroy -target=module.composer.google_composer_environment.privesc30_target
# =============================================================================
