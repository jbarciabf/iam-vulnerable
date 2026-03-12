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

# Compute Engine paths (11-15)
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

# Cloud Functions path (17)
variable "enable_privesc17" {
  description = "Enable privesc17: updateFunction"
  type        = bool
  default     = false
}

# Cloud Run paths (18-21)
variable "enable_privesc18" {
  description = "Enable privesc18: actAs + run.services.create"
  type        = bool
  default     = false
}

variable "enable_privesc19" {
  description = "Enable privesc19: run.services.update"
  type        = bool
  default     = false
}

variable "enable_privesc20" {
  description = "Enable privesc20: run.jobs.create"
  type        = bool
  default     = false
}

variable "enable_privesc21" {
  description = "Enable privesc21: run.jobs.update"
  type        = bool
  default     = false
}

# Cloud Scheduler update (25) - requires existing scheduler job
variable "enable_privesc25" {
  description = "Enable privesc25: cloudscheduler.jobs.update (requires existing scheduler job to hijack)"
  type        = bool
  default     = false
}

# Deployment Manager update (27) - creates target deployment (GCS bucket ~$0.02/mo)
variable "enable_privesc27" {
  description = "Enable privesc27: deploymentmanager.deployments.update (creates target deployment to hijack)"
  type        = bool
  default     = false
}

# Composer Update (29) - creates target Composer environment (~$400/mo!)
variable "enable_privesc29" {
  description = "Enable privesc29: composer.environments.update (creates target Composer environment to hijack - ~$400/mo!)"
  type        = bool
  default     = false
}

# Dataflow Update (31) - requires existing streaming Dataflow job
variable "enable_privesc31" {
  description = "Enable privesc31: dataflow.jobs.updateContents (requires existing streaming Dataflow job to hijack)"
  type        = bool
  default     = false
}

# Notebooks Update (37) - needs verification
variable "enable_privesc37" {
  description = "Enable privesc37: notebooks.instances.setIamPolicy (hijack existing notebook)"
  type        = bool
  default     = false
}

# Workflows Update (40) - hijack existing workflow
variable "enable_privesc40" {
  description = "Enable privesc40: workflows.workflows.update (hijack existing workflow)"
  type        = bool
  default     = false
}

# Eventarc Triggers Update (42) - hijack existing trigger
variable "enable_privesc42" {
  description = "Enable privesc42: eventarc.triggers.update (hijack existing trigger)"
  type        = bool
  default     = false
}

# Workload Identity Update (44) - hijack existing provider
variable "enable_privesc44" {
  description = "Enable privesc44: iam.workloadIdentityPoolProviders.update (hijack existing provider)"
  type        = bool
  default     = false
}

# Org Policy (45) - requires organization
variable "enable_privesc45" {
  description = "Enable privesc45: orgpolicy.policy.set (requires GCP organization)"
  type        = bool
  default     = false
}
