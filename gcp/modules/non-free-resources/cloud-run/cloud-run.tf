# GCP Cloud Run Module
#
# This module creates Cloud Run infrastructure for privilege escalation testing:
#   1. A token-extractor container image (built via Cloud Build)
#   2. A target Cloud Run service running as high-priv SA (for Path 20)
#
# COST ESTIMATE:
#   - Cloud Build: ~$0.003 per build minute (usually < $0.01 per build)
#   - Artifact Registry: ~$0.10/GB/month (image is < 50MB, so < $0.01/month)
#   - Cloud Run: Free tier covers 2M requests/month, scales to zero when idle
#   - Total: < $0.10/month for typical testing use
#
# EXPLOITATION SCENARIOS:
#   - Path 19: Deploy token-extractor as new service with high-priv SA
#   - Path 20: Update existing service to use token-extractor image
#   - Path 21: Create Cloud Run job using token-extractor image

# Enable required APIs
resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "cloudbuild" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# Create Artifact Registry repository for the token-extractor image
resource "google_artifact_registry_repository" "privesc" {
  project       = var.project_id
  location      = var.region
  repository_id = "privesc-images"
  format        = "DOCKER"
  description   = "Container images for privilege escalation testing"

  depends_on = [google_project_service.artifactregistry]
}

# Allow the attacker and privesc SAs to pull images from the repository
# This simulates access to a public image - the SAs don't need artifactregistry
# permissions in their custom roles
resource "google_artifact_registry_repository_iam_binding" "attacker_reader" {
  project    = var.project_id
  location   = var.region
  repository = google_artifact_registry_repository.privesc.name
  role       = "roles/artifactregistry.reader"
  members = compact([
    var.attacker_member,
    var.privesc19_sa_email != null ? "serviceAccount:${var.privesc19_sa_email}" : null,
    var.privesc20_sa_email != null ? "serviceAccount:${var.privesc20_sa_email}" : null,
    var.privesc21_sa_email != null ? "serviceAccount:${var.privesc21_sa_email}" : null,
    var.privesc22_sa_email != null ? "serviceAccount:${var.privesc22_sa_email}" : null,
  ])
}

# Build the token-extractor image using Cloud Build
# The Dockerfile and server.py are stored in the token-extractor subdirectory
resource "null_resource" "build_token_extractor" {
  triggers = {
    # Rebuild when source files change
    dockerfile_hash = filemd5("${path.module}/token-extractor/Dockerfile")
    server_hash     = filemd5("${path.module}/token-extractor/server.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/token-extractor && \
      gcloud builds submit \
        --project=${var.project_id} \
        --tag=${var.region}-docker.pkg.dev/${var.project_id}/privesc-images/token-extractor:latest \
        --impersonate-service-account="" \
        --quiet
    EOT
  }

  depends_on = [
    google_artifact_registry_repository.privesc,
    google_project_service.cloudbuild,
  ]
}

# Cloud Run service with high-priv SA (target for Path 20: run.services.update)
# Only created when path 20 is enabled - path 19 creates its own service
resource "google_cloud_run_v2_service" "privesc_service" {
  count = var.enable_privesc20 ? 1 : 0

  name     = "privesc20-run-service"
  project  = var.project_id
  location = var.region

  template {
    service_account = var.high_priv_sa_email

    containers {
      # Use the token-extractor image we built
      image = "${var.region}-docker.pkg.dev/${var.project_id}/privesc-images/token-extractor:latest"

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        cpu_idle = true # Only allocate CPU during requests (cheaper, allows lower memory)
      }
    }

    scaling {
      min_instance_count = 0
      max_instance_count = 1
    }
  }

  depends_on = [
    google_project_service.run,
    null_resource.build_token_extractor,
  ]
}

# Cloud Run job with high-priv SA (target for Path 22: run.jobs.update)
# Only created when path 22 is enabled - path 21 creates its own job
resource "google_cloud_run_v2_job" "privesc_job" {
  count = var.enable_privesc22 ? 1 : 0

  name     = "privesc22-run-job"
  project  = var.project_id
  location = var.region

  template {
    template {
      service_account = var.high_priv_sa_email

      containers {
        image = "${var.region}-docker.pkg.dev/${var.project_id}/privesc-images/token-extractor:latest"

        resources {
          limits = {
            cpu    = "1"
            memory = "512Mi"
          }
        }
      }

      max_retries = 0
    }
  }

  depends_on = [
    google_project_service.run,
    null_resource.build_token_extractor,
  ]
}

# Outputs
output "service_name" {
  description = "Name of the target Cloud Run service (path 20 only)"
  value       = var.enable_privesc20 ? google_cloud_run_v2_service.privesc_service[0].name : null
}

output "service_url" {
  description = "URL of the Cloud Run service (path 20 only)"
  value       = var.enable_privesc20 ? google_cloud_run_v2_service.privesc_service[0].uri : null
}

output "token_extractor_image" {
  description = "Token extractor image URL for use in exploitation"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/privesc-images/token-extractor:latest"
}

output "attached_service_account" {
  description = "Service account attached to the service"
  value       = var.high_priv_sa_email
}

output "job_name" {
  description = "Name of the target Cloud Run job (path 22 only)"
  value       = var.enable_privesc22 ? google_cloud_run_v2_job.privesc_job[0].name : null
}
