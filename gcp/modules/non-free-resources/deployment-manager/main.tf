# GCP Deployment Manager Module - Target Deployment for Privesc28
#
# This module creates a Deployment Manager deployment that can be hijacked via
# deploymentmanager.deployments.update for privilege escalation.
#
# COST: ~$0.02/month (GCS bucket for placeholder deployment)
#
# NOTE: Deployment Manager will reach end of support on March 31, 2026

# =============================================================================
# TARGET INFRASTRUCTURE: Existing deployment to hijack
# =============================================================================

# Simple target deployment that can be modified via update
# This creates a minimal GCS bucket - attacker will update to add a VM with high-priv SA
resource "google_deployment_manager_deployment" "privesc28_target" {
  name    = "${var.resource_prefix}28-target"
  project = var.project_id

  target {
    config {
      content = <<-EOF
        resources:
        - name: ${var.resource_prefix}28-placeholder
          type: storage.v1.bucket
          properties:
            name: ${var.project_id}-privesc28-placeholder
            location: US
            storageClass: STANDARD
      EOF
    }
  }

  labels {
    key   = "purpose"
    value = "privesc28-target"
  }
}

# =============================================================================
# Outputs
# =============================================================================

output "target_deployment_name" {
  description = "Name of the target Deployment Manager deployment for privesc28"
  value       = google_deployment_manager_deployment.privesc28_target.name
}
