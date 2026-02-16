# Privesc Path 31: Dataproc Clusters with Privileged SA
#
# VULNERABILITY: A user with dataproc.clusters.create and actAs can create
# Dataproc clusters that execute with a high-privilege service account.
#
# EXPLOITATION:
#   1. Create a Dataproc cluster with high-priv SA
#   2. SSH to master/worker nodes
#   3. Access SA credentials via metadata server
#   4. Make privileged API calls as the SA
#
# DETECTION: FoxMapper detects this via the dataprocClustersCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Full cluster access as privileged SA
#
# NOTE: Creating Dataproc clusters incurs cost (~$0.10/hr minimum)
#       This path only creates the IAM configuration, not the cluster

resource "google_service_account" "privesc31_dataproc" {
  account_id   = "${var.resource_prefix}31-dataproc"
  display_name = "Privesc31 - Dataproc Clusters"
  description  = "Can escalate via dataproc.clusters.create"
  project      = var.project_id

  depends_on = [time_sleep.batch7_delay]
}

# Create a custom role with Dataproc permissions
resource "google_project_iam_custom_role" "privesc31_dataproc" {
  role_id     = "${var.resource_prefix}_31_dataproc"
  title       = "Privesc31 Dataproc Cluster Creator"
  description = "Can create Dataproc clusters"
  project     = var.project_id

  permissions = [
    "dataproc.clusters.create",
    "dataproc.clusters.get",
    "dataproc.clusters.list",
    "dataproc.operations.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc31_dataproc" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc31_dataproc.id
  member  = "serviceAccount:${google_service_account.privesc31_dataproc.email}"
}

# Grant actAs on the high-privilege SA
resource "google_service_account_iam_member" "privesc31_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc31_dataproc.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc31_impersonate" {
  service_account_id = google_service_account.privesc31_dataproc.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
