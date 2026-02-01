# GCP Tool Testing Module - Outputs

output "test_service_accounts" {
  description = "Map of test names to their service account emails"
  value = {
    # False Negative tests (SHOULD be detected as privesc)
    "fn1-exploitable-condition" = google_service_account.fn1_exploitable_condition.email
    "fn2-indirect-actAs"        = google_service_account.fn2_indirect_actas.email
    "fn3-chained-escalation"    = google_service_account.fn3_hop1.email

    # False Positive tests (should NOT be detected as privesc)
    "fp1-restrictive-condition" = google_service_account.fp1_restrictive_condition.email
    "fp2-deny-policy"           = google_service_account.fp2_denied.email
    "fp3-scope-limited"         = google_service_account.fp3_scope_limited.email
    "fp4-no-target"             = google_service_account.fp4_no_target.email
  }
}

output "test_targets" {
  description = "Target service accounts used in tests"
  value = {
    "fn2-target"       = google_service_account.fn2_target.email
    "fn3-hop2"         = google_service_account.fn3_hop2.email
    "fn3-hop3-owner"   = google_service_account.fn3_hop3.email
    "fp4-unprivileged" = google_service_account.fp4_unprivileged_target.email
  }
}
