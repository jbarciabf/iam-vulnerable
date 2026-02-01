# GCP Privesc Paths Module - Common Resources
#
# This file contains shared resources used across multiple privilege escalation paths.

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
