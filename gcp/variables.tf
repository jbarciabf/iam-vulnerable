# GCP IAM Vulnerable - Variables

variable "gcp_project_id" {
  description = "GCP project ID to deploy vulnerable resources into. Use an isolated test project only."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources (e.g., Compute Engine instances)"
  type        = string
  default     = "us-central1-a"
}

variable "attacker_member" {
  description = <<-EOT
    GCP IAM member that should have access to vulnerable resources.
    Format: "user:email@example.com" or "serviceAccount:sa@project.iam.gserviceaccount.com"
    If not specified, defaults to the user running Terraform.
  EOT
  type        = string
  default     = ""
}

variable "resource_prefix" {
  description = "Prefix for all created resources (helps identify iam-vulnerable resources)"
  type        = string
  default     = "privesc"
}

# =============================================================================
# MODULE TOGGLES - Enable/disable optional modules
# =============================================================================

variable "enable_compute" {
  description = "Enable Compute Engine module (creates VM with privileged SA). Cost: ~$2-3/month"
  type        = bool
  default     = false
}

variable "enable_cloud_functions" {
  description = "Enable Cloud Functions module (creates function with privileged SA). Cost: Free tier"
  type        = bool
  default     = false
}

variable "enable_cloud_run" {
  description = "Enable Cloud Run module (creates service with privileged SA). Cost: Free tier"
  type        = bool
  default     = false
}
