# GCP Cloud Functions Module
#
# This module creates a Cloud Function with a high-privilege service account,
# demonstrating serverless privilege escalation.
#
# COST: Usually covered by free tier for testing
#
# EXPLOITATION SCENARIOS:
#   1. Invoke function to execute code as high-priv SA
#   2. Update function code to inject malicious logic

# Get project details for the compute service account
data "google_project" "project" {
  project_id = var.project_id
}

# Enable required APIs
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

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project = var.project_id
  service = "run.googleapis.com"

  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false
}

# Grant the default compute service account access to Cloud Storage
# Required for Cloud Functions to access the source bucket
resource "google_project_iam_member" "compute_storage_access" {
  project = var.project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.storage
  ]
}

# Grant compute SA permissions to build functions (for Gen2 when using custom build SA)
resource "google_project_iam_member" "compute_artifactregistry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"

  depends_on = [google_project_service.artifactregistry]
}

resource "google_project_iam_member" "compute_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
}

# Grant Cloud Build SA the ability to write to Artifact Registry (required for Gen2)
resource "google_project_iam_member" "cloudbuild_artifactregistry" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild,
    google_project_service.artifactregistry
  ]
}

# Grant Cloud Build SA logging permissions
resource "google_project_iam_member" "cloudbuild_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

  depends_on = [
    google_project_service.cloudbuild
  ]
}

# Wait for IAM propagation
resource "time_sleep" "wait_for_iam" {
  depends_on = [
    google_project_iam_member.compute_storage_access,
    google_project_iam_member.compute_artifactregistry,
    google_project_iam_member.compute_logging,
    google_project_iam_member.cloudbuild_artifactregistry,
    google_project_iam_member.cloudbuild_logging
  ]
  create_duration = "90s"
}

# Storage bucket for function source code
resource "google_storage_bucket" "function_bucket" {
  name     = "${var.project_id}-${var.resource_prefix}-functions"
  project  = var.project_id
  location = var.region

  uniform_bucket_level_access = true

  # Clean up on destroy
  force_destroy = true
}

# Create the function source code as a zip archive
data "archive_file" "function_source" {
  type        = "zip"
  output_path = "${path.module}/function-source.zip"

  source {
    content  = <<-EOF
import functions_framework

@functions_framework.http
def handler(request):
    return 'Hello from privesc function!'
EOF
    filename = "main.py"
  }

  source {
    content  = <<-EOF
functions-framework==3.*
EOF
    filename = "requirements.txt"
  }
}

# Upload the function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_source.output_path
}

# Cloud Function Gen2 with high-priv SA
resource "google_cloudfunctions2_function" "privesc_function" {
  name        = "${var.resource_prefix}-function"
  project     = var.project_id
  location    = var.region
  description = "Function running with high-privilege SA"

  build_config {
    runtime     = "python312"
    entry_point = "handler"
    source {
      storage_source {
        bucket = google_storage_bucket.function_bucket.name
        object = google_storage_bucket_object.function_source.name
      }
    }
    # Use default compute SA for build if org policy disables default Cloud Build SA
    service_account = "projects/${var.project_id}/serviceAccounts/${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  }

  service_config {
    max_instance_count    = 1
    available_memory      = "128Mi"
    timeout_seconds       = 60
    service_account_email = var.high_priv_sa_email
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    google_project_service.run,
    google_project_service.artifactregistry,
    time_sleep.wait_for_iam
  ]
}

# Allow unauthenticated invocation (for testing)
resource "google_cloud_run_service_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.privesc_function.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Outputs
output "function_name" {
  description = "Name of the created function"
  value       = google_cloudfunctions2_function.privesc_function.name
}

output "function_url" {
  description = "HTTP trigger URL"
  value       = google_cloudfunctions2_function.privesc_function.service_config[0].uri
}

output "attached_service_account" {
  description = "Service account attached to the function"
  value       = var.high_priv_sa_email
}
