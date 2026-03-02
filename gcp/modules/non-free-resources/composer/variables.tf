# GCP Composer Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "high_priv_sa_email" {
  description = "Email of the high-privilege service account to attach to the Composer environment"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}
