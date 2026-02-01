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

# Individual privesc path toggles (disabled by default)
variable "enable_privesc11" {
  description = "Enable privesc11: setMetadata-compute"
  type        = bool
  default     = false
}

variable "enable_privesc12" {
  description = "Enable privesc12: osLogin"
  type        = bool
  default     = false
}

variable "enable_privesc13" {
  description = "Enable privesc13: setServiceAccount"
  type        = bool
  default     = false
}

variable "enable_privesc16" {
  description = "Enable privesc16: updateFunction"
  type        = bool
  default     = false
}

variable "enable_privesc17" {
  description = "Enable privesc17: sourceCodeSet"
  type        = bool
  default     = false
}

variable "enable_privesc19" {
  description = "Enable privesc19: run.services.update"
  type        = bool
  default     = false
}

variable "enable_privesc42" {
  description = "Enable privesc42: orgpolicy.policy.set"
  type        = bool
  default     = false
}
