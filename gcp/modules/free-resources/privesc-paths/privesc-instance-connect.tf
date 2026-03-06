# Instance Connect Service Account
#
# DEPRECATED: SSH access for completing compute-based privesc paths is now
# handled by the project-level SSH user role granted to the attacker identity
# in common.tf. This SA is kept for backwards compatibility but can be removed
# if you're deploying fresh.
#
# The attacker's own identity now has compute.instances.setMetadata,
# compute.instances.get, compute.instances.list, compute.projects.get,
# and compute.zones.list at the project level, allowing direct SSH access
# to any instance without needing to impersonate a separate SA.

resource "google_service_account" "instance_connect" {
  account_id   = "${var.resource_prefix}-instance-connect"
  display_name = "Privesc Instance Connect - SSH completion (deprecated)"
  description  = "Deprecated - SSH now handled by project-level SSH user role on attacker identity"
  project      = var.project_id

  depends_on = [time_sleep.batch1_delay]
}
