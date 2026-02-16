# Privesc Path 16: Instance Templates with Privileged SA
#
# This path has three sub-paths demonstrating different levels of exploitation:
#
# Path 16a: Template Creation Only (Persistence/Staging)
#   - Can create templates with high-priv SA but cannot spawn instances
#   - Requires waiting for someone else to use the template
#   - Low immediate impact, but useful for persistence
#
# Path 16b: Template + Instance Creation (Full Exploitation)
#   - Can create templates AND spawn instances from them
#   - Full escalation path - SSH to VM and get SA token
#
# Path 16c: Template + MIG Creation
#   - Can create templates AND managed instance groups
#   - MIG automatically spawns VMs with high-priv SA
#
# DETECTION: FoxMapper detects these via the instanceTemplatesCreate edge checker
#
# REAL-WORLD IMPACT: Varies by sub-path (see above)

# =============================================================================
# Path 16a: Instance Templates Only (Persistence/Staging)
# =============================================================================

resource "google_service_account" "privesc16a_inst_templates" {
  account_id   = "${var.resource_prefix}16a-inst-templ"
  display_name = "Privesc16a - Instance Templates Only"
  description  = "Can create templates but not instances (persistence mechanism)"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

resource "google_project_iam_custom_role" "privesc16a_inst_templates" {
  role_id     = "${var.resource_prefix}_16a_inst_templates"
  title       = "Privesc16a Instance Templates Only"
  description = "Can create instance templates (no instance creation)"
  project     = var.project_id

  permissions = [
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instanceTemplates.delete",
    # Supporting permissions (required to validate network during template creation)
    "compute.networks.get",
    "compute.subnetworks.get",
  ]
}

resource "google_project_iam_member" "privesc16a_inst_templates" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc16a_inst_templates.id
  member  = "serviceAccount:${google_service_account.privesc16a_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16a_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc16a_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16a_impersonate" {
  service_account_id = google_service_account.privesc16a_inst_templates.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# =============================================================================
# Path 16b: Instance Templates + Instance Creation (Full Exploitation)
# =============================================================================

resource "google_service_account" "privesc16b_inst_templates" {
  account_id   = "${var.resource_prefix}16b-inst-templ"
  display_name = "Privesc16b - Templates + Instances"
  description  = "Can create templates and spawn instances (full exploitation)"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

resource "google_project_iam_custom_role" "privesc16b_inst_templates" {
  role_id     = "${var.resource_prefix}_16b_inst_templates"
  title       = "Privesc16b Templates + Instances"
  description = "Can create instance templates and spawn instances"
  project     = var.project_id

  permissions = [
    # Template permissions
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instanceTemplates.delete",
    "compute.instanceTemplates.useReadOnly",
    # Instance creation permissions
    "compute.instances.create",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.delete",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    # Disk permissions (required for instance creation)
    "compute.disks.create",
    # Network permissions (required for template creation and SSH access)
    "compute.networks.get",
    "compute.subnetworks.get",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    # Project permissions (required for SSH)
    "compute.projects.get",
    # Zone listing
    "compute.zones.list",
  ]
}

resource "google_project_iam_member" "privesc16b_inst_templates" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc16b_inst_templates.id
  member  = "serviceAccount:${google_service_account.privesc16b_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16b_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc16b_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16b_impersonate" {
  service_account_id = google_service_account.privesc16b_inst_templates.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# =============================================================================
# Path 16c: Instance Templates + MIG Creation
# =============================================================================

resource "google_service_account" "privesc16c_inst_templates" {
  account_id   = "${var.resource_prefix}16c-inst-templ"
  display_name = "Privesc16c - Templates + MIG"
  description  = "Can create templates and managed instance groups"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

resource "google_project_iam_custom_role" "privesc16c_inst_templates" {
  role_id     = "${var.resource_prefix}_16c_inst_templates"
  title       = "Privesc16c Templates + MIG"
  description = "Can create instance templates and managed instance groups"
  project     = var.project_id

  permissions = [
    # Template permissions
    "compute.instanceTemplates.create",
    "compute.instanceTemplates.get",
    "compute.instanceTemplates.list",
    "compute.instanceTemplates.delete",
    "compute.instanceTemplates.useReadOnly",
    # MIG permissions
    "compute.instanceGroupManagers.create",
    "compute.instanceGroupManagers.get",
    "compute.instanceGroupManagers.list",
    "compute.instanceGroupManagers.delete",
    "compute.instanceGroupManagers.update",
    "compute.instanceGroups.create",
    "compute.instanceGroups.get",
    "compute.instanceGroups.list",
    "compute.instanceGroups.delete",
    # Instance permissions (MIG creates instances on your behalf)
    "compute.instances.create",
    "compute.instances.get",
    "compute.instances.list",
    "compute.instances.delete",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    # Disk permissions (required for instance creation)
    "compute.disks.create",
    # Network permissions (required for template creation)
    "compute.networks.get",
    "compute.subnetworks.get",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    # Project permissions (required for SSH)
    "compute.projects.get",
    # Zone listing
    "compute.zones.list",
  ]
}

resource "google_project_iam_member" "privesc16c_inst_templates" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc16c_inst_templates.id
  member  = "serviceAccount:${google_service_account.privesc16c_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16c_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc16c_inst_templates.email}"
}

resource "google_service_account_iam_member" "privesc16c_impersonate" {
  service_account_id = google_service_account.privesc16c_inst_templates.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
