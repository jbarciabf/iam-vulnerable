# GCP Cloud Run Module
#
# This module creates a Cloud Run service with a high-privilege service account,
# demonstrating container-based privilege escalation.
#
# COST: Usually covered by free tier for testing
#
# EXPLOITATION SCENARIOS:
#   1. Invoke service to execute code as high-priv SA
#   2. Update service to deploy malicious container

# Enable required APIs
resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

# Cloud Run service with high-priv SA
resource "google_cloud_run_service" "privesc_service" {
  name     = "${var.resource_prefix}-service"
  project  = var.project_id
  location = var.region

  template {
    spec {
      # Attach high-privilege service account
      service_account_name = var.high_priv_sa_email

      containers {
        # Use a simple public image for testing
        image = "gcr.io/cloudrun/hello"

        resources {
          limits = {
            cpu    = "1"
            memory = "128Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "1"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run]
}

# Allow unauthenticated invocation (for testing)
resource "google_cloud_run_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloud_run_service.privesc_service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Outputs
output "service_name" {
  description = "Name of the created service"
  value       = google_cloud_run_service.privesc_service.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_service.privesc_service.status[0].url
}

output "attached_service_account" {
  description = "Service account attached to the service"
  value       = var.high_priv_sa_email
}
