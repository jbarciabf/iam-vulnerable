# GCP Dataflow Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the Dataflow job"
  type        = string
}

variable "high_priv_sa_email" {
  description = "Email of the high-privilege service account to run the Dataflow job"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}
