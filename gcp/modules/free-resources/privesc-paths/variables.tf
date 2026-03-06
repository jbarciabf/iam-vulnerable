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
variable "enable_privesc11" {
  description = "Enable privesc11: setMetadata-compute via manual key injection"
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Enable privesc12: setCommonInstanceMetadata (project-level SSH key injection)"
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Enable privesc13: osLogin"
  type        = bool
  default     = false
}

variable "enable_privesc14" {
  description = "Enable privesc14: setServiceAccount"
  type        = bool
  default     = false
}

variable "enable_lateral7" {
  description = "Enable lateral7: Existing SSH access to VM with high-priv SA"
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

# Composer Update (30) - creates target Composer environment (~$400/mo!)
variable "enable_privesc30" {
  description = "Enable privesc30: composer.environments.update (creates target Composer environment to hijack - ~$400/mo!)"
  type        = bool
  default     = false
}

# Dataflow Update (32) - requires existing streaming Dataflow job
variable "enable_privesc32" {
  description = "Enable privesc32: dataflow.jobs.updateContents (requires existing streaming Dataflow job to hijack)"
  type        = bool
  default     = false
}

# Notebooks Update (38) - needs verification
variable "enable_privesc38" {
  description = "Enable privesc38: notebooks.instances.setIamPolicy (hijack existing notebook)"
  type        = bool
  default     = false
}

# Workflows Update (41) - hijack existing workflow
variable "enable_privesc41" {
  description = "Enable privesc41: workflows.workflows.update (hijack existing workflow)"
  type        = bool
  default     = false
}

# Eventarc Triggers Update (43) - hijack existing trigger
variable "enable_privesc43" {
  description = "Enable privesc43: eventarc.triggers.update (hijack existing trigger)"
  type        = bool
  default     = false
}

# Workload Identity Update (45) - hijack existing provider
variable "enable_privesc45" {
  description = "Enable privesc45: iam.workloadIdentityPoolProviders.update (hijack existing provider)"
  type        = bool
  default     = false
}

# Org Policy (46) - requires organization
variable "enable_privesc46" {
  description = "Enable privesc46: orgpolicy.policy.set (requires GCP organization)"
  type        = bool
  default     = false
}
