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
variable "enable_privesc11a" {
  description = "Create instance for privesc11a (setMetadata gcloud ssh)"
  type        = bool
  default     = false
}

variable "enable_privesc11b" {
  description = "Create instance for privesc11b (setMetadata manual)"
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Create instance for privesc12 (setCommonInstanceMetadata)"
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Create instance for privesc13 (existingSSH)"
  type        = bool
  default     = false
}

variable "enable_privesc14" {
  description = "Create instance for privesc14 (osLogin)"
  type        = bool
  default     = false
}

variable "enable_privesc15" {
  description = "Create instance for privesc15 (setServiceAccount)"
  type        = bool
  default     = false
}
