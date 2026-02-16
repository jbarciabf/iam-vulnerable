# Privesc Path 34: GKE Get Credentials
#
# VULNERABILITY: A service account with container.clusters.getCredentials
# can obtain kubeconfig credentials to access GKE clusters, potentially
# gaining access to Kubernetes secrets or pods running with privileged SAs.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Get credentials for a GKE cluster
#   3. Access Kubernetes API
#   4. List secrets, access pods, or exploit workload identity
#   5. Extract service account tokens from pods
#
# DETECTION: FoxMapper detects this via the containerGetCredentials edge checker
#
# REAL-WORLD IMPACT: High - Access to Kubernetes cluster and its secrets

resource "google_service_account" "privesc34_gke_creds" {
  account_id   = "${var.resource_prefix}34-gke-creds"
  display_name = "Privesc34 - container.clusters.getCredentials"
  description  = "Can escalate via GKE cluster credential access"
  project      = var.project_id

  depends_on = [time_sleep.batch8_delay]
}

# Create a custom role with GKE credential permissions
resource "google_project_iam_custom_role" "privesc34_gke_creds" {
  role_id     = "${var.resource_prefix}_34_gke_creds"
  title       = "Privesc34 GKE Credential Viewer"
  description = "Can get credentials for GKE clusters"
  project     = var.project_id

  permissions = [
    "container.clusters.getCredentials",
    "container.clusters.get",
    "container.clusters.list",
  ]
}

# Grant the custom role at project level
resource "google_project_iam_member" "privesc34_gke_creds" {
  project = var.project_id
  role    = google_project_iam_custom_role.privesc34_gke_creds.id
  member  = "serviceAccount:${google_service_account.privesc34_gke_creds.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc34_impersonate" {
  service_account_id = google_service_account.privesc34_gke_creds.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
