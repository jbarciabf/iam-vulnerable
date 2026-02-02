# Privesc Path 14: Instance Templates with Privileged SA
#
# VULNERABILITY: A user with compute.instanceTemplates.create and actAs can
# create instance templates that use a high-privilege service account.
#
# EXPLOITATION:
#   1. Create an instance template with high-priv SA attached
#   2. Create a managed instance group using the template
#   3. VMs created from the template have access to high-priv SA
#   4. SSH to VM and extract tokens from metadata
#
# DETECTION: FoxMapper detects this via the instanceTemplatesCreate edge checker
#
# REAL-WORLD IMPACT: High - Persistent SA access through templates

resource "google_service_account" "privesc14_instance_templates" {
  account_id   = "${var.resource_prefix}14-inst-templates"
  display_name = "Privesc14 - Instance Templates"
  description  = "Can escalate via compute.instanceTemplates.create"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Create a custom role with ONLY instance template permissions
# Removed: compute.instances.create, compute.disks.create, compute.subnetworks.*
# These were enabling alternative attack paths (direct instance creation)
resource "google_project_iam_custom_role" "privesc14_instance_templates" {
  role_id     = "${var.resource_prefix}_14_inst_templates"
  title       = "Privesc14 Instance Templates Creator"
  description = "Can create instance templates (restricted to templates only)"
  project     = var.project_id

  permissions = [
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc14_instance_templates" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc14_instance_templates.id
  member  = "serviceAccount:${google_service_account.privesc14_instance_templates.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc14_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc14_instance_templates.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc14_impersonate" {
  service_account_id = google_service_account.privesc14_instance_templates.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
