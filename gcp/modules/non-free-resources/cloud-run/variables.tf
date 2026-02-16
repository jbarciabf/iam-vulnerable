# GCP Cloud Run Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "attacker_member" {
  description = "IAM member to grant access"
  type        = string
}

variable "high_priv_sa_email" {
  description = "Email of the high-privilege service account"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}

variable "privesc19_sa_email" {
  description = "Email of privesc19 SA (for Artifact Registry access)"
  type        = string
  default     = null
}

variable "privesc20_sa_email" {
  description = "Email of privesc20 SA (for Artifact Registry access)"
  type        = string
  default     = null
}

variable "privesc21_sa_email" {
  description = "Email of privesc21 SA (for Artifact Registry access)"
  type        = string
  default     = null
}

variable "privesc22_sa_email" {
  description = "Email of privesc22 SA (for Artifact Registry access)"
  type        = string
  default     = null
}

variable "enable_privesc20" {
  description = "Whether to create the target service for path 20 (run.services.update)"
  type        = bool
  default     = false
}

variable "enable_privesc22" {
  description = "Whether to create the target job for path 22 (run.jobs.update)"
  type        = bool
  default     = false
}
