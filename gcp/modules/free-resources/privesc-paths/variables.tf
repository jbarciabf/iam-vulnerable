# GCP Privesc Paths Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_number" {
  description = "GCP project number"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "attacker_member" {
  description = "IAM member to grant access to vulnerable resources"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}

# =============================================================================
# Individual privesc path toggles (disabled by default)
# =============================================================================
# These paths are disabled because they require target infrastructure (costs money)
# or a GCP Organization to fully exploit.

# Compute Engine paths (11-16)
variable "enable_privesc11a" {
  description = "Enable privesc11a: setMetadata-compute via gcloud compute ssh (auto key injection)"
  type        = bool
  default     = false
}

variable "enable_privesc11b" {
  description = "Enable privesc11b: setMetadata-compute via manual key injection"
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Enable privesc12: setCommonInstanceMetadata (project-level SSH key injection)"
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Enable privesc13: Existing SSH access to VM with high-priv SA"
  type        = bool
  default     = false
}

variable "enable_privesc14" {
  description = "Enable privesc14: osLogin"
  type        = bool
  default     = false
}

variable "enable_privesc15" {
  description = "Enable privesc15: setServiceAccount"
  type        = bool
  default     = false
}

# Cloud Functions path (18)
variable "enable_privesc18" {
  description = "Enable privesc18: updateFunction"
  type        = bool
  default     = false
}

# Cloud Run paths (19-22)
variable "enable_privesc19" {
  description = "Enable privesc19: actAs + run.services.create"
  type        = bool
  default     = false
}

variable "enable_privesc20" {
  description = "Enable privesc20: run.services.update"
  type        = bool
  default     = false
}

variable "enable_privesc21" {
  description = "Enable privesc21: run.jobs.create"
  type        = bool
  default     = false
}

variable "enable_privesc22" {
  description = "Enable privesc22: run.jobs.update"
  type        = bool
  default     = false
}

# Cloud Scheduler update (26) - requires existing scheduler job
variable "enable_privesc26" {
  description = "Enable privesc26: cloudscheduler.jobs.update (requires existing scheduler job to hijack)"
  type        = bool
  default     = false
}

# Deployment Manager update (28) - creates target deployment (GCS bucket ~$0.02/mo)
variable "enable_privesc28" {
  description = "Enable privesc28: deploymentmanager.deployments.update (creates target deployment to hijack)"
  type        = bool
  default     = false
}

# Org Policy (40) - requires organization
variable "enable_privesc40" {
  description = "Enable privesc40: orgpolicy.policy.set (requires GCP organization)"
  type        = bool
  default     = false
}
