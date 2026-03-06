# Privesc Path 36: Vertex AI Notebooks with Privileged SA
#
# VULNERABILITY: A user with notebooks.instances.create and actAs can create
# Vertex AI notebook instances that run with a high-privilege service account.
#
# EXPLOITATION:
#   1. Create a Vertex AI notebook with high-priv SA
#   2. Access the notebook via the console or JupyterLab
#   3. Execute code that accesses the SA credentials
#   4. Make privileged API calls from within the notebook
#
# DETECTION: FoxMapper detects this via the notebooksInstancesCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Interactive shell as privileged SA
#
# NOTE: Creating notebook instances incurs cost (~$25/mo minimum)
#       This path only creates the IAM configuration, not the notebook

resource "google_service_account" "privesc36_notebooks" {
  account_id   = "${var.resource_prefix}36-notebooks"
  display_name = "Privesc36 - Vertex AI Notebooks"
  description  = "Can escalate via notebooks.instances.create"
  project      = var.project_id

  depends_on = [time_sleep.batch8_delay]
}

# Create a custom role with Notebooks permissions
resource "google_project_iam_custom_role" "privesc36_notebooks" {
  role_id     = "${var.resource_prefix}_36_notebooks"
  title       = "Privesc36 Notebook Instance Creator"
  description = "Can create Vertex AI notebook instances"
  project     = var.project_id

  permissions = [
    "notebooks.instances.create",
    "notebooks.instances.get",
    "notebooks.instances.list",
    "notebooks.operations.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc36_notebooks" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc36_notebooks.id
  member  = "serviceAccount:${google_service_account.privesc36_notebooks.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc36_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc36_notebooks.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc36_impersonate" {
  service_account_id = google_service_account.privesc36_notebooks.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
