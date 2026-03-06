# GCP Privesc Paths Module - Outputs

output "high_priv_service_account_email" {
  description = "Email of the high-privilege target service account"
  value       = google_service_account.high_priv.email
}

output "medium_priv_service_account_email" {
  description = "Email of the medium-privilege service account"
  value       = google_service_account.medium_priv.email
}

output "iam_viewer_service_account_email" {
  description = "Email of the IAM Viewer SA (for enumeration/reconnaissance)"
  value       = google_service_account.iam_viewer.email
}

output "instance_connect_service_account_email" {
  description = "Email of the instance connect SA (for SSH completion steps)"
  value       = google_service_account.instance_connect.email
}

output "privesc_service_accounts" {
  description = "Map of all privilege escalation service account emails"
  value = merge(
    {
      # Utility SA for completing compute-based privesc paths
      "privesc-instance-connect" = google_service_account.instance_connect.email

      # IAM Service Account (1-9) - Always enabled
      "privesc01-setIamPolicy-project"        = google_service_account.privesc1_set_iam_policy.email
      "privesc02-createServiceAccountKey"     = google_service_account.privesc2_create_key.email
      "privesc03-setIamPolicy-serviceAccount" = google_service_account.privesc3_set_sa_iam.email
      "privesc04-getAccessToken"              = google_service_account.privesc4_get_access_token.email
      "privesc05-signBlob"                    = google_service_account.privesc5_sign_blob.email
      "privesc06-signJwt"                     = google_service_account.privesc6_sign_jwt.email
      "privesc07-implicitDelegation"          = google_service_account.privesc7_implicit_delegation.email
      "privesc08-getOpenIdToken"              = google_service_account.privesc8_get_oidc_token.email
      "privesc09-updateRole"                  = google_service_account.privesc9_update_role.email

      # Compute Engine (10, 16a-c) - Always enabled
      "privesc10-actAs-compute"      = google_service_account.privesc10_actas_compute.email
      "privesc16a-instanceTemplates" = google_service_account.privesc16a_inst_templates.email
      "privesc16b-instanceTemplates" = google_service_account.privesc16b_inst_templates.email
      "privesc16c-instanceTemplates" = google_service_account.privesc16c_inst_templates.email

      # Cloud Functions (17) - Always enabled
      "privesc17-actAs-cloudfunction" = google_service_account.privesc17_actas_function.email

      # Cloud Build (23a, 23b, 24) - Always enabled
      "privesc23a-actAs-cloudbuild"      = google_service_account.privesc23a_actas_cloudbuild.email
      "privesc23b-cloudbuildTriggers"    = google_service_account.privesc23b_triggers.email
      "privesc24-cloudbuildBuildsUpdate" = google_service_account.privesc24_builds_update.email

      # Cloud Scheduler (25) - Always enabled
      "privesc25-cloudSchedulerCreate" = google_service_account.privesc25_scheduler.email

      # Deployment Manager (27) - Always enabled
      "privesc27-deploymentManager" = google_service_account.privesc27_deployment_manager.email

      # Composer (29) - Always enabled
      "privesc29-composer" = google_service_account.privesc29_composer.email

      # Dataflow (31) - Always enabled
      "privesc31-dataflow" = google_service_account.privesc31_dataflow.email

      # Dataproc (33-34) - Always enabled
      "privesc33-dataprocClusters"   = google_service_account.privesc33_dataproc.email
      "privesc34-dataprocJobsCreate" = google_service_account.privesc34_dataproc_jobs.email

      # GKE/Kubernetes (35-36) - Always enabled
      "privesc35-gkeCluster"        = google_service_account.privesc35_gke.email
      "privesc36-gkeGetCredentials" = google_service_account.privesc36_gke_creds.email

      # Vertex AI / AI Platform (37, 39) - Always enabled
      "privesc37-notebooksInstances"   = google_service_account.privesc37_notebooks.email
      "privesc39-aiplatformCustomJobs" = google_service_account.privesc39_aiplatform.email

      # Cloud Workflows (40) - Always enabled
      "privesc40-workflowsCreate" = google_service_account.privesc40_workflows.email

      # Eventarc (42) - Always enabled
      "privesc42-eventarcTriggersCreate" = google_service_account.privesc42_eventarc.email

      # Workload Identity (44) - Always enabled
      "privesc44-workloadIdentity" = google_service_account.privesc44_workload_identity.email

      # Deny Bypass (47) - Always enabled
      "privesc47-explicitDeny-bypass" = google_service_account.privesc47_deny_bypass.email
    },
    # Conditionally enabled paths (require target infrastructure)
    var.enable_privesc11 ? { "privesc11-setMetadata" = google_service_account.privesc11_set_metadata[0].email } : {},
    var.enable_privesc12 ? { "privesc12-setCommonInstanceMetadata" = google_service_account.privesc12_set_common_metadata[0].email } : {},
    var.enable_privesc13 ? { "privesc13-osLogin" = google_service_account.privesc13_os_login[0].email } : {},
    var.enable_privesc14 ? { "privesc14-setServiceAccount" = google_service_account.privesc14_set_sa[0].email } : {},
    var.enable_lateral7 ? { "lateral7-existingSSH" = google_service_account.lateral7_existing_ssh[0].email } : {},
    var.enable_privesc18 ? { "privesc18-updateFunction" = google_service_account.privesc18_update_function[0].email } : {},
    var.enable_privesc19 ? { "privesc19-actAs-cloudrun" = google_service_account.privesc19_actas_cloudrun[0].email } : {},
    var.enable_privesc20 ? { "privesc20-runServicesUpdate" = google_service_account.privesc20_run_update[0].email } : {},
    var.enable_privesc21 ? { "privesc21-runJobsCreate" = google_service_account.privesc21_run_jobs[0].email } : {},
    var.enable_privesc22 ? { "privesc22-runJobsUpdate" = google_service_account.privesc22_run_jobs_update[0].email } : {},
    var.enable_privesc26 ? { "privesc26-cloudSchedulerUpdate" = google_service_account.privesc26_scheduler_update[0].email } : {},
    var.enable_privesc28 ? { "privesc28-deploymentManagerUpdate" = google_service_account.privesc28_dm_update[0].email } : {},
    var.enable_privesc30 ? { "privesc30-composerUpdate" = google_service_account.privesc30_composer_update[0].email } : {},
    var.enable_privesc32 ? { "privesc32-dataflowUpdate" = google_service_account.privesc32_dataflow_update[0].email } : {},
    var.enable_privesc38 ? { "privesc38-notebooksUpdate" = google_service_account.privesc38_notebooks_update[0].email } : {},
    var.enable_privesc41 ? { "privesc41-workflowsUpdate" = google_service_account.privesc41_workflows_update[0].email } : {},
    var.enable_privesc43 ? { "privesc43-eventarcTriggersUpdate" = google_service_account.privesc43_eventarc_update[0].email } : {},
    var.enable_privesc45 ? { "privesc45-workloadIdentityUpdate" = google_service_account.privesc45_workload_identity_update[0].email } : {},
    var.enable_privesc46 ? { "privesc46-orgPolicySet" = google_service_account.privesc46_org_policy[0].email } : {},
  )
}

# Cloud Run SA emails for Artifact Registry access
output "privesc19_sa_email" {
  description = "Email of privesc19 SA (if enabled)"
  value       = var.enable_privesc19 ? google_service_account.privesc19_actas_cloudrun[0].email : null
}

output "privesc20_sa_email" {
  description = "Email of privesc20 SA (if enabled)"
  value       = var.enable_privesc20 ? google_service_account.privesc20_run_update[0].email : null
}

output "privesc21_sa_email" {
  description = "Email of privesc21 SA (if enabled)"
  value       = var.enable_privesc21 ? google_service_account.privesc21_run_jobs[0].email : null
}

output "privesc22_sa_email" {
  description = "Email of privesc22 SA (if enabled)"
  value       = var.enable_privesc22 ? google_service_account.privesc22_run_jobs_update[0].email : null
}

# Privesc8 WIF pool details (needed for OIDC → access token exchange)
output "privesc08_wif_pool_name" {
  description = "Full resource name of the WIF pool for privesc08 OIDC exchange"
  value       = google_iam_workload_identity_pool.privesc8_pool.name
}

output "privesc08_wif_provider_name" {
  description = "Full resource name of the WIF provider for privesc08 OIDC exchange"
  value       = google_iam_workload_identity_pool_provider.privesc8_provider.name
}

# NOTE: privesc26 target job, privesc28 target deployment, and privesc30 target
# composer environment outputs are now in their respective non-free modules:
#   - modules/non-free-resources/cloud-scheduler
#   - modules/non-free-resources/deployment-manager
#   - modules/non-free-resources/composer

# =============================================================================
# LATERAL MOVEMENT PATHS (Data Access, NOT Privilege Escalation)
# =============================================================================

output "lateral_service_accounts" {
  description = "Map of lateral movement service account emails (data access, not privesc)"
  value = {
    # Storage (1-2) - Always enabled
    "lateral1-setIamPolicy-bucket"  = google_service_account.lateral1_bucket_iam.email
    "lateral2-storageObjectsCreate" = google_service_account.lateral2_storage_write.email

    # Secret Manager (3-4) - Always enabled
    "lateral3-secretManagerAccess"       = google_service_account.lateral3_secret_access.email
    "lateral4-secretManagerSetIamPolicy" = google_service_account.lateral4_secret_set_iam.email

    # Pub/Sub (5) - Always enabled
    "lateral5-setIamPolicy-pubsub" = google_service_account.lateral5_pubsub_iam.email

    # BigQuery (6) - Always enabled
    "lateral6-bigquerySetIamPolicy" = google_service_account.lateral6_bigquery.email
  }
}
