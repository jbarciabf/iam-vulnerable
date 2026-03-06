variable "gcp_project_id" {
  description = "The GCP project ID to deploy attacker infrastructure into"
  type        = string
}

variable "gcp_region" {
  description = "The GCP region for resources"
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone for the attacker instance"
  type        = string
  default     = "us-central1-a"
}

variable "enable_attacker_instance" {
  description = "Set to true to create the attacker compute instance (spot e2-micro, ~$2-5/mo). Set to false to destroy only the instance while keeping the bucket, VPC, and SSH key."
  type        = bool
  default     = true
}

variable "enable_certbot" {
  description = "Set to true to request a Let's Encrypt TLS certificate on boot using sslip.io (no DNS setup needed). Override the domain with dns_name if you have a custom domain. Email is derived from your GCP account."
  type        = bool
  default     = false
}

variable "dns_name" {
  description = "Optional custom DNS name for the TLS certificate (e.g., attacker.example.com). If empty, defaults to EXTERNAL-IP.sslip.io (free, no setup needed). Only used when enable_certbot = true."
  type        = string
  default     = ""
}
