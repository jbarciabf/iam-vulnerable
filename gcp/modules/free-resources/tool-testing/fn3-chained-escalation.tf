# False Negative Test 3: Multi-Hop Escalation Chain
#
# SCENARIO: A service account can escalate, but only through multiple hops:
#   SA1 -> SA2 -> SA3 -> Owner
#
# EXPECTED TOOL BEHAVIOR:
#   - Tool SHOULD detect the full escalation chain
#   - All intermediate hops should be reported
#
# WHY IT'S A FALSE NEGATIVE IF MISSED:
#   - Real attacks often involve multiple escalation steps
#   - Depth-limited analysis may miss these paths

resource "google_service_account" "fn3_hop1" {
  account_id   = "${var.resource_prefix}-fn3-hop1"
  display_name = "FN3 - Hop 1"
  description  = "First hop in escalation chain"
  project      = var.project_id

  depends_on = [time_sleep.tt_batch2_delay]
}

resource "google_service_account" "fn3_hop2" {
  account_id   = "${var.resource_prefix}-fn3-hop2"
  display_name = "FN3 - Hop 2"
  description  = "Second hop in escalation chain"
  project      = var.project_id

  depends_on = [time_sleep.tt_batch2_delay]
}

resource "google_service_account" "fn3_hop3" {
  account_id   = "${var.resource_prefix}-fn3-hop3"
  display_name = "FN3 - Hop 3 (Target)"
  description  = "Final hop - has Owner"
  project      = var.project_id

  depends_on = [time_sleep.tt_batch2_delay]
}

# Hop3 has Owner
resource "google_project_iam_member" "fn3_hop3_owner" {
  project = var.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.fn3_hop3.email}"
}

# Hop2 can impersonate Hop3
resource "google_service_account_iam_member" "fn3_hop2_to_hop3" {
  service_account_id = google_service_account.fn3_hop3.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.fn3_hop2.email}"
}

# Hop1 can impersonate Hop2
resource "google_service_account_iam_member" "fn3_hop1_to_hop2" {
  service_account_id = google_service_account.fn3_hop2.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.fn3_hop1.email}"
}

# Allow attacker to impersonate Hop1
resource "google_service_account_iam_member" "fn3_attacker" {
  service_account_id = google_service_account.fn3_hop1.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = var.attacker_member
}
