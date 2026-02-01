# Privesc Path 27: setIamPolicy on Pub/Sub Resources
#
# VULNERABILITY: A service account with pubsub.topics.setIamPolicy or
# pubsub.subscriptions.setIamPolicy can grant access to message data.
#
# EXPLOITATION:
#   1. Impersonate the attacking service account
#   2. Find Pub/Sub topics or subscriptions with sensitive data
#   3. Grant yourself subscriber/publisher access
#   4. Read messages or publish malicious messages
#
# DETECTION: FoxMapper detects this via pubsub IAM edge checker
#
# REAL-WORLD IMPACT: High - Message interception, data exfiltration

resource "google_service_account" "privesc27_pubsub_iam" {
  account_id   = "${var.resource_prefix}21-pubsub-iam"
  display_name = "Privesc21 - Pub/Sub IAM"
  description  = "Can modify Pub/Sub IAM policies"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Custom role with Pub/Sub IAM permissions
resource "google_project_iam_custom_role" "pubsub_iam" {
  role_id     = "${var.resource_prefix}_pubsubIam"
  title       = "Privesc - Pub/Sub IAM"
  description = "Vulnerable: Can modify Pub/Sub IAM policies"
  permissions = [
    "pubsub.topics.list",
    "pubsub.topics.get",
    "pubsub.topics.getIamPolicy",
    "pubsub.topics.setIamPolicy",
    "pubsub.subscriptions.list",
    "pubsub.subscriptions.get",
    "pubsub.subscriptions.getIamPolicy",
    "pubsub.subscriptions.setIamPolicy",
  ]
  project = var.project_id
}

# Assign the role
resource "google_project_iam_member" "privesc27_role" {
  project = var.project_id
  role    = google_project_iam_custom_role.pubsub_iam.id
  member  = "serviceAccount:${google_service_account.privesc27_pubsub_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc27_impersonate" {
  service_account_id = google_service_account.privesc27_pubsub_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
