# GCP Deployment Manager Module - Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "privesc"
}
