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
# PRIVESC PATH TOGGLES - Disabled by default (require infrastructure or org)
# =============================================================================
# These privesc paths are disabled by default because they either:
# - Require actual infrastructure to exploit (costs money)
# - Require a GCP Organization
#
# Enable individually as needed. Each creates both the IAM resources AND
# the target infrastructure required to exploit the path.

variable "enable_privesc11" {
  description = "Privesc11: setMetadata-compute. Creates VM (~$2-5/mo) to demonstrate metadata-based escalation."
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Privesc12: osLogin. Creates VM (~$2-5/mo) to demonstrate OS Login escalation."
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Privesc13: setServiceAccount. Creates VM (~$2-5/mo) to demonstrate SA swapping."
  type        = bool
  default     = false
}

variable "enable_privesc16" {
  description = "Privesc16: updateFunction. Creates Cloud Function (free when idle) to demonstrate function update escalation."
  type        = bool
  default     = false
}

variable "enable_privesc17" {
  description = "Privesc17: sourceCodeSet. Creates Cloud Function (free when idle) to demonstrate source code injection."
  type        = bool
  default     = false
}

variable "enable_privesc19" {
  description = "Privesc19: run.services.update. Creates Cloud Run service (free when idle) to demonstrate service update escalation."
  type        = bool
  default     = false
}

variable "enable_privesc42" {
  description = "Privesc42: orgpolicy.policy.set. Requires GCP Organization (set gcp_organization_id)."
  type        = bool
  default     = false
}

# =============================================================================
# ORGANIZATION SETTINGS (Optional)
# =============================================================================

variable "gcp_organization_id" {
  description = <<-EOT
    GCP Organization ID for org-level privilege escalation paths (e.g., orgpolicy.policy.set).
    Format: "123456789012" (numeric organization ID)
    If not specified, org-level privesc paths will only demonstrate project-level IAM bindings.
    Note: GCP Organizations cannot be created via Terraform - they require a verified domain
    through Google Workspace or Cloud Identity.
  EOT
  type        = string
  default     = ""
}

# =============================================================================
# PROJECT CREATION (Optional)
# =============================================================================

variable "create_project" {
  description = <<-EOT
    If true, Terraform will create the GCP project specified by gcp_project_id.
    If false (default), the project must already exist.
    Requires billing_account to be set when true.
  EOT
  type        = bool
  default     = false
}

variable "billing_account" {
  description = <<-EOT
    GCP Billing Account ID to link to the project. Required if create_project = true.
    Format: "XXXXXX-XXXXXX-XXXXXX"
    Find yours with: gcloud billing accounts list
  EOT
  type        = string
  default     = ""
}
