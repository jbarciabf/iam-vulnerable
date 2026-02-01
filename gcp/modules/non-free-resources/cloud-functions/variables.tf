# GCP Cloud Functions Module - Variables

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
