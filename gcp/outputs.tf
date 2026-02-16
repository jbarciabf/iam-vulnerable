# GCP IAM Vulnerable - Outputs
#
# These outputs provide information about the vulnerable resources created.
# Use these values when testing with FoxMapper, gcpwn, or other tools.

output "project_id" {
  description = "GCP project ID where vulnerable resources were created"
  value       = var.gcp_project_id
}

output "attacker_member" {
  description = "IAM member configured as the attacker"
  value       = local.attacker_member
}

output "high_priv_service_account" {
  description = "High-privilege service account email (target for escalation)"
  value       = module.privesc-paths.high_priv_service_account_email
}

output "privesc_service_accounts" {
  description = "Map of privilege escalation path names to their service account emails"
  value       = module.privesc-paths.privesc_service_accounts
}


# Summary output for quick reference
output "summary" {
  description = "Summary of created resources"
  value       = <<-EOT

    ====================================================================
    GCP IAM Vulnerable - Deployment Summary
    ====================================================================

    Project: ${var.gcp_project_id}
    Region:  ${var.gcp_region}

    Attacker Identity: ${local.attacker_member}

    High-Privilege Target Service Account:
      ${module.privesc-paths.high_priv_service_account_email}

    Modules Enabled:
      - privesc-paths:    Yes (33 enabled + 13 disabled by default)
      - tool-testing:     ${var.enable_tool_testing ? "Yes (7 tests)" : "Disabled"}

    Disabled Privesc Paths (enable individually):
      - privesc11a (setMetadata gcloud):  ${var.enable_privesc11a ? "Enabled" : "Disabled"}
      - privesc11b (setMetadata manual):  ${var.enable_privesc11b ? "Enabled" : "Disabled"}
      - privesc12 (setCommonInstanceMetadata): ${var.enable_privesc12 ? "Enabled" : "Disabled"}
      - privesc13 (existingSSH):          ${var.enable_privesc13 ? "Enabled" : "Disabled"}
      - privesc14 (osLogin):              ${var.enable_privesc14 ? "Enabled" : "Disabled"}
      - privesc15 (setServiceAccount):    ${var.enable_privesc15 ? "Enabled" : "Disabled"}
      - privesc18 (updateFunction):       ${var.enable_privesc18 ? "Enabled" : "Disabled"}
      - privesc19 (run.services.create):  ${var.enable_privesc19 ? "Enabled" : "Disabled"}
      - privesc20 (run.services.update):  ${var.enable_privesc20 ? "Enabled" : "Disabled"}
      - privesc21 (run.jobs.create):      ${var.enable_privesc21 ? "Enabled" : "Disabled"}
      - privesc22 (run.jobs.update):      ${var.enable_privesc22 ? "Enabled" : "Disabled"}
      - privesc26 (scheduler.jobs.update): ${var.enable_privesc26 ? "Enabled" : "Disabled"}
      - privesc28 (dm.deployments.update): ${var.enable_privesc28 ? "Enabled" : "Disabled"}
      - privesc40 (orgpolicy.policy.set): ${var.enable_privesc40 ? "Enabled" : "Disabled"}

    Privilege Escalation Paths Created:
    ${join("\n    ", [for name, email in module.privesc-paths.privesc_service_accounts : "- ${name}: ${email}"])}

  EOT
}
