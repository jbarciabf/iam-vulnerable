# Privesc Path 33: GKE Cluster with Privileged Node SA
#
# VULNERABILITY: A user with container.clusters.create and actAs can create
# GKE clusters whose nodes run with a high-privilege service account.
#
# EXPLOITATION:
#   1. Create a GKE cluster with high-priv SA for nodes
#   2. Get cluster credentials
#   3. Deploy a pod that accesses the metadata server
#   4. Exfiltrate node SA token with high privileges
#
# DETECTION: FoxMapper detects this via the containerClustersCreate edge checker
#
# REAL-WORLD IMPACT: Critical - Kubernetes cluster running as privileged SA
#
# NOTE: Creating GKE clusters incurs cost (~$70/mo minimum)
#       This path only creates the IAM configuration, not the cluster

resource "google_service_account" "privesc33_gke" {
  account_id   = "${var.resource_prefix}33-gke"
  display_name = "Privesc33 - GKE Clusters"
  description  = "Can escalate via container.clusters.create"
  project      = var.project_id

  depends_on = [time_sleep.batch8_delay]
}

# Create a custom role with GKE permissions
resource "google_project_iam_custom_role" "privesc33_gke" {
  role_id     = "${var.resource_prefix}_33_gke"
  title       = "Privesc33 GKE Cluster Creator"
  description = "Can create GKE clusters"
  project     = var.project_id

  permissions = [
    "container.clusters.create",
    "container.clusters.get",
    "container.clusters.list",
    "container.clusters.getCredentials",
    "container.operations.get",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc33_gke" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc33_gke.id
  member  = "serviceAccount:${google_service_account.privesc33_gke.email}"
}

# Grant actAs on the high-privilege SA (for node identity)
resource "google_service_account_iam_member" "privesc33_actas" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc33_gke.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc33_impersonate" {
  service_account_id = google_service_account.privesc33_gke.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
