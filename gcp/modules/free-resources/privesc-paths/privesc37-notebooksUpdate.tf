# Privesc Path 37: Vertex AI Notebooks Update (Set IAM Policy)
#
# VULNERABILITY: A service account with notebooks.instances.setIamPolicy can
# grant itself access to an existing Vertex AI notebook instance running with
# a high-privilege service account, then execute code as that SA.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. List notebook instances to find ones with privileged SAs
#   3. Set IAM policy on the notebook to grant yourself access
#   4. Access the notebook via JupyterLab UI
#   5. Execute code that accesses the SA credentials
#   6. Make privileged API calls
#
# DETECTION: FoxMapper detects this via the notebooksUpdate edge checker
#
# REAL-WORLD IMPACT: Critical - Hijack existing notebook to access privileged SA
#
# NOTE: This path is DISABLED by default (enable_privesc37 = false)
#       Needs verification that setIamPolicy on notebooks grants code execution.
#       Enable with: enable_privesc37 = true

resource "google_service_account" "privesc37_notebooks_update" {
  count = var.enable_privesc37 ? 1 : 0

  account_id   = "${var.resource_prefix}37-notebooks-upd"
  display_name = "Privesc37 - notebooks.instances.setIamPolicy"
  description  = "Can escalate via notebook IAM policy modification"
  project      = var.project_id

  depends_on = [time_sleep.batch9_delay]
}

# Custom role with Notebooks IAM policy permissions
resource "google_project_iam_custom_role" "privesc37_notebooks_update" {
  count = var.enable_privesc37 ? 1 : 0

  role_id     = "${var.resource_prefix}_37_notebooks_update"
  title       = "Privesc37 Notebook IAM Policy Setter"
  description = "Can set IAM policy on Vertex AI notebook instances"
  project     = var.project_id

  permissions = [
    "notebooks.instances.setIamPolicy",
    "notebooks.instances.getIamPolicy",
    "notebooks.instances.get",
    "notebooks.instances.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc37_notebooks_update" {
  count = var.enable_privesc37 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc37_notebooks_update[0].id
  member  = "serviceAccount:${google_service_account.privesc37_notebooks_update[0].email}"
}

# Grant actAs on the high-privilege SA (needed to set self as SA on the notebook via IAM policy)
resource "google_service_account_iam_member" "privesc37_actas" {
  count = var.enable_privesc37 ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc37_notebooks_update[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc37_impersonate" {
  count = var.enable_privesc37 ? 1 : 0

  service_account_id = google_service_account.privesc37_notebooks_update[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
