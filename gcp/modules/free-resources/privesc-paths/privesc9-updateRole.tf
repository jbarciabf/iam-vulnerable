# Privesc Path 9: Update Custom Role
#
# VULNERABILITY: A service account with iam.roles.update on a custom role it
# holds can add any permissions to that role.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Identify a custom role assigned to the attacker
#   3. Update the role to add powerful permissions (e.g., setIamPolicy)
#   4. Use the newly granted permissions
#
# DETECTION: FoxMapper detects this via the updateRole edge checker
#
# REAL-WORLD IMPACT: High - Self-escalation through role modification

resource "google_service_account" "privesc9_update_role" {
  account_id   = "${var.resource_prefix}9-update-role"
  display_name = "Privesc9 - Update Role"
  description  = "Can escalate by modifying custom roles"
  project      = var.project_id

  depends_on = [time_sleep.batch3_delay]
}

# Create a custom role that the SA has
resource "google_project_iam_custom_role" "modifiable_role" {
  role_id     = "${var.resource_prefix}_09_modifiableRole"
  title       = "Privesc09 - Modifiable Role"
  description = "A role that can be modified by its holder"
  permissions = [
    "resourcemanager.projects.get",
    "iam.roles.get",
    "iam.roles.list",
    "iam.roles.update",
  ]
  project = var.project_id
}

# Assign the modifiable role to the service account
resource "google_project_iam_member" "privesc9_modifiable" {
  project = var.project_id
  role    = google_project_iam_custom_role.modifiable_role.id
  member  = "serviceAccount:${google_service_account.privesc9_update_role.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc9_impersonate" {
  service_account_id = google_service_account.privesc9_update_role.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
