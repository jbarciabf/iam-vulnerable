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

# Grant the default compute service account access to Cloud Storage
# Required for Cloud Functions Gen1 to access the gcf-sources bucket
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

# Wait for IAM propagation
resource "time_sleep" "wait_for_iam" {
  depends_on      = [google_project_iam_member.compute_storage_access]
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
      exports.handler = (req, res) => {
        res.send('Hello from privesc function!');
      };
    EOF
    filename = "index.js"
  }
}

# Upload the function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_bucket.name
  source = data.archive_file.function_source.output_path
}

# Cloud Function with high-priv SA
resource "google_cloudfunctions_function" "privesc_function" {
  name        = "${var.resource_prefix}-function"
  project     = var.project_id
  region      = var.region
  description = "Function running with high-privilege SA"

  runtime = "nodejs20"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.function_bucket.name
  source_archive_object = google_storage_bucket_object.function_source.name
  trigger_http          = true
  entry_point           = "handler"

  # Attach high-privilege service account
  service_account_email = var.high_priv_sa_email

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild,
    time_sleep.wait_for_iam
  ]
}

# Allow unauthenticated invocation (for testing)
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.privesc_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# Outputs
output "function_name" {
  description = "Name of the created function"
  value       = google_cloudfunctions_function.privesc_function.name
}

output "function_url" {
  description = "HTTP trigger URL"
  value       = google_cloudfunctions_function.privesc_function.https_trigger_url
}

output "attached_service_account" {
  description = "Service account attached to the function"
  value       = var.high_priv_sa_email
}
