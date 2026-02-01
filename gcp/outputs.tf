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

output "vulnerable_custom_roles" {
  description = "List of vulnerable custom roles created"
  value       = module.privesc-paths.vulnerable_custom_roles
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

    Privilege Escalation Paths Created:
    ${join("\n    ", [for name, email in module.privesc-paths.privesc_service_accounts : "- ${name}: ${email}"])}

    Tool Testing Resources:
    ${join("\n    ", [for name, email in module.tool-testing.test_service_accounts : "- ${name}: ${email}"])}

    ====================================================================
    Test with FoxMapper:
      foxmapper gcp graph create --project ${var.gcp_project_id}
      foxmapper gcp argquery --preset privesc --project ${var.gcp_project_id}
    ====================================================================

  EOT
}
