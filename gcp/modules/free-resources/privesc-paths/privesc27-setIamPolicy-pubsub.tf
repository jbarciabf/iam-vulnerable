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
  account_id   = "${var.resource_prefix}27-pubsub-iam"
  display_name = "Privesc27 - Pub/Sub IAM"
  description  = "Can modify Pub/Sub IAM policies"
  project      = var.project_id

  depends_on = [time_sleep.batch6_delay]
}

# Grant admin ONLY on the target topic (not project-wide)
# This prevents the attacker from modifying IAM on other topics
resource "google_pubsub_topic_iam_member" "privesc27_topic_admin" {
  topic  = google_pubsub_topic.target_topic.name
  role   = "roles/pubsub.admin"
  member = "serviceAccount:${google_service_account.privesc27_pubsub_iam.email}"
}

# Grant admin ONLY on the target subscription
resource "google_pubsub_subscription_iam_member" "privesc27_subscription_admin" {
  subscription = google_pubsub_subscription.target_subscription.name
  role         = "roles/pubsub.admin"
  member       = "serviceAccount:${google_service_account.privesc27_pubsub_iam.email}"
}

# Allow the attacker to impersonate this service account
resource "google_service_account_iam_member" "privesc27_impersonate" {
  service_account_id = google_service_account.privesc27_pubsub_iam.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
