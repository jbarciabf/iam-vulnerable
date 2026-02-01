# GCP Tool Testing Module - Common Resources
#
# Rate Limiting for Service Account Creation
# GCP limits service account creation to ~5-10 per minute per project.
# These time_sleep resources batch the creation of service accounts.
#
# Tool-testing creates 11 SAs total, split into 2 batches:
#   Batch TT1 (immediate): fn1, fn2, fp1, fp2, fp3 (6 SAs)
#   Batch TT2 (after delay): fn3, fp4 (5 SAs)

resource "time_sleep" "tt_batch1_delay" {
  create_duration = "0s" # First batch starts immediately (after privesc-paths completes)
}

resource "time_sleep" "tt_batch2_delay" {
  depends_on      = [time_sleep.tt_batch1_delay]
  create_duration = "65s" # Wait after batch 1
}
