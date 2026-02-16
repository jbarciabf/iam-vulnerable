# Instance Connect Service Account
#
# This service account has the permissions needed to complete exploitation
# for compute-based privesc paths (10, 15, 16b, 16c) by SSHing into instances.
#
# PERMISSIONS:
#   - compute.subnetworks.use - Attach to subnet
#   - compute.subnetworks.useExternalIp - Get external IP
#   - compute.instances.setMetadata - Inject SSH keys via gcloud compute ssh
#
# USAGE:
#   After creating a VM with a high-priv SA (paths 10, 16b, 16c) or changing
#   a VM's SA (path 15), impersonate this SA to SSH into the instance:
#
#   gcloud config set auth/impersonate_service_account \
#     privesc-instance-connect@PROJECT_ID.iam.gserviceaccount.com
#   gcloud compute ssh INSTANCE_NAME --zone=us-central1-a

resource "google_service_account" "instance_connect" {
  account_id   = "${var.resource_prefix}-instance-connect"
  display_name = "Privesc Instance Connect - SSH completion"
  description  = "Has permissions to SSH into instances for completing compute-based privesc paths"
  project      = var.project_id

  depends_on = [time_sleep.batch1_delay]
}

# Custom role with instance connect permissions
resource "google_project_iam_custom_role" "instance_connect" {
  role_id     = "${var.resource_prefix}_instance_connect"
  title       = "Privesc Instance Connect"
  description = "Permissions to SSH into compute instances (completion step for privesc paths)"
  permissions = [
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.instances.setMetadata",
    "compute.instances.get",
    "compute.instances.list",
    "compute.zones.list",
    "compute.projects.get",
  ]
  project = var.project_id
}

# Grant the custom role to the instance connect SA
resource "google_project_iam_member" "instance_connect_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.instance_connect.id
  member  = "serviceAccount:${google_service_account.instance_connect.email}"
}

# Allow attacker to impersonate this SA
resource "google_service_account_iam_member" "instance_connect_impersonate" {
  service_account_id = google_service_account.instance_connect.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on the high-priv SA so we can SSH into VMs running as high-priv SA
# (gcloud compute ssh requires actAs permission on the VM's service account to modify metadata)
resource "google_service_account_iam_member" "instance_connect_actas_high_priv" {
  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.instance_connect.email}"
}
