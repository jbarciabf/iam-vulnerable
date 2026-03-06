# GCP Compute Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone"
  type        = string
}

variable "attacker_member" {
  description = "IAM member to grant access"
  type        = string
}

variable "high_priv_sa_email" {
  description = "Email of the high-privilege service account to attach to instances"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}

# Per-path instance toggles
variable "enable_privesc11" {
  description = "Create instance for privesc11 (setMetadata manual key injection)"
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Create instance for privesc12 (setCommonInstanceMetadata)"
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Create instance for privesc13 (osLogin)"
  type        = bool
  default     = false
}

variable "enable_privesc14" {
  description = "Create instance for privesc14 (setServiceAccount)"
  type        = bool
  default     = false
}

variable "enable_lateral7" {
  description = "Create instance for lateral7 (existingSSH)"
  type        = bool
  default     = false
}
