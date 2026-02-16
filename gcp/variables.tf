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

variable "enable_tool_testing" {
  description = "Enable the tool-testing module (creates additional SAs for testing security tools). Disable if hitting SA quota limits."
  type        = bool
  default     = false
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

# Compute Engine paths (11-15)
variable "enable_privesc11a" {
  description = "Privesc11a: setMetadata via gcloud compute ssh. Creates VM (~$2-5/mo) with auto key injection."
  type        = bool
  default     = false
}

variable "enable_privesc11b" {
  description = "Privesc11b: setMetadata via manual key injection. Creates VM (~$2-5/mo) with manual SSH key injection."
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Privesc12: setCommonInstanceMetadata (project-level). Creates VM (~$2-5/mo) to demonstrate project-wide SSH key injection."
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Privesc13: Existing SSH access. Creates VM (~$2-5/mo) with attacker SSH key already in metadata."
  type        = bool
  default     = false
}

variable "enable_privesc14" {
  description = "Privesc14: osLogin. Creates VM (~$2-5/mo) to demonstrate OS Login escalation."
  type        = bool
  default     = false
}

variable "enable_privesc15" {
  description = "Privesc15: setServiceAccount. Creates VM (~$2-5/mo) to demonstrate SA swapping."
  type        = bool
  default     = false
}

# Cloud Functions path (18)
variable "enable_privesc18" {
  description = "Privesc18: updateFunction. Creates Cloud Function (free when idle) to demonstrate function update escalation."
  type        = bool
  default     = false
}

# Cloud Run paths (19-22)
# Cost: < $0.10/month (Cloud Build, Artifact Registry, Cloud Run all have generous free tiers)
variable "enable_privesc19" {
  description = "Privesc19: actAs + run.services.create. Creates token-extractor image and Cloud Run infrastructure."
  type        = bool
  default     = false
}

variable "enable_privesc20" {
  description = "Privesc20: run.services.update. Creates target Cloud Run service."
  type        = bool
  default     = false
}

variable "enable_privesc21" {
  description = "Privesc21: run.jobs.create. Creates token-extractor image for job deployment."
  type        = bool
  default     = false
}

variable "enable_privesc22" {
  description = "Privesc22: run.jobs.update. Creates target Cloud Run job."
  type        = bool
  default     = false
}

# Cloud Scheduler Update (26)
variable "enable_privesc26" {
  description = "Privesc26: cloudscheduler.jobs.update. Creates target scheduler job to hijack."
  type        = bool
  default     = false
}

# Deployment Manager Update (28)
variable "enable_privesc28" {
  description = "Privesc28: deploymentmanager.deployments.update. Creates target deployment to hijack (~$0.02/mo for GCS bucket)."
  type        = bool
  default     = false
}

# Org Policy (40)
variable "enable_privesc40" {
  description = "Privesc40: orgpolicy.policy.set. Requires GCP Organization (set gcp_organization_id)."
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
