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

      # Compute Engine (10, 15a-c) - Always enabled
      "privesc10-actAs-compute"      = google_service_account.privesc10_actas_compute.email
      "privesc15a-instanceTemplates" = google_service_account.privesc15a_inst_templates.email
      "privesc15b-instanceTemplates" = google_service_account.privesc15b_inst_templates.email
      "privesc15c-instanceTemplates" = google_service_account.privesc15c_inst_templates.email

      # Cloud Functions (16) - Always enabled
      "privesc16-actAs-cloudfunction" = google_service_account.privesc16_actas_function.email

      # Cloud Build (22a, 22b, 23) - Always enabled
      "privesc22a-actAs-cloudbuild"      = google_service_account.privesc22a_actas_cloudbuild.email
      "privesc22b-cloudbuildTriggers"    = google_service_account.privesc22b_triggers.email
      "privesc23-cloudbuildBuildsUpdate" = google_service_account.privesc23_builds_update.email

      # Cloud Scheduler (24) - Always enabled
      "privesc24-cloudSchedulerCreate" = google_service_account.privesc24_scheduler.email

      # Deployment Manager (26) - Always enabled
      "privesc26-deploymentManager" = google_service_account.privesc26_deployment_manager.email

      # Composer (28) - Always enabled
      "privesc28-composer" = google_service_account.privesc28_composer.email

      # Dataflow (30) - Always enabled
      "privesc30-dataflow" = google_service_account.privesc30_dataflow.email

      # Dataproc (32-33) - Always enabled
      "privesc32-dataprocClusters"   = google_service_account.privesc32_dataproc.email
      "privesc33-dataprocJobsCreate" = google_service_account.privesc33_dataproc_jobs.email

      # GKE/Kubernetes (34-35) - Always enabled
      "privesc34-gkeCluster"        = google_service_account.privesc34_gke.email
      "privesc35-gkeGetCredentials" = google_service_account.privesc35_gke_creds.email

      # Vertex AI / AI Platform (36, 38) - Always enabled
      "privesc36-notebooksInstances"   = google_service_account.privesc36_notebooks.email
      "privesc38-aiplatformCustomJobs" = google_service_account.privesc38_aiplatform.email

      # Cloud Workflows (39) - Always enabled
      "privesc39-workflowsCreate" = google_service_account.privesc39_workflows.email

      # Eventarc (41) - Always enabled
      "privesc41-eventarcTriggersCreate" = google_service_account.privesc41_eventarc.email

      # Workload Identity (43) - Always enabled
      "privesc43-workloadIdentity" = google_service_account.privesc43_workload_identity.email

      # Deny Bypass (46) - Always enabled
      "privesc46-explicitDeny-bypass" = google_service_account.privesc46_deny_bypass.email
    },
    # Conditionally enabled paths (require target infrastructure)
    var.enable_privesc11 ? { "privesc11-setMetadata" = google_service_account.privesc11_set_metadata[0].email } : {},
    var.enable_privesc12 ? { "privesc12-setCommonInstanceMetadata" = google_service_account.privesc12_set_common_metadata[0].email } : {},
    var.enable_privesc13 ? { "privesc13-osLogin" = google_service_account.privesc13_os_login[0].email } : {},
    var.enable_privesc14 ? { "privesc14-setServiceAccount" = google_service_account.privesc14_set_sa[0].email } : {},
    var.enable_lateral7 ? { "lateral7-existingSSH" = google_service_account.lateral7_existing_ssh[0].email } : {},
    var.enable_privesc17 ? { "privesc17-updateFunction" = google_service_account.privesc17_update_function[0].email } : {},
    var.enable_privesc18 ? { "privesc18-actAs-cloudrun" = google_service_account.privesc18_actas_cloudrun[0].email } : {},
    var.enable_privesc19 ? { "privesc19-runServicesUpdate" = google_service_account.privesc19_run_update[0].email } : {},
    var.enable_privesc20 ? { "privesc20-runJobsCreate" = google_service_account.privesc20_run_jobs[0].email } : {},
    var.enable_privesc21 ? { "privesc21-runJobsUpdate" = google_service_account.privesc21_run_jobs_update[0].email } : {},
    var.enable_privesc25 ? { "privesc25-cloudSchedulerUpdate" = google_service_account.privesc25_scheduler_update[0].email } : {},
    var.enable_privesc27 ? { "privesc27-deploymentManagerUpdate" = google_service_account.privesc27_dm_update[0].email } : {},
    var.enable_privesc29 ? { "privesc29-composerUpdate" = google_service_account.privesc29_composer_update[0].email } : {},
    var.enable_privesc31 ? { "privesc31-dataflowUpdate" = google_service_account.privesc31_dataflow_update[0].email } : {},
    var.enable_privesc37 ? { "privesc37-notebooksUpdate" = google_service_account.privesc37_notebooks_update[0].email } : {},
    var.enable_privesc40 ? { "privesc40-workflowsUpdate" = google_service_account.privesc40_workflows_update[0].email } : {},
    var.enable_privesc42 ? { "privesc42-eventarcTriggersUpdate" = google_service_account.privesc42_eventarc_update[0].email } : {},
    var.enable_privesc44 ? { "privesc44-workloadIdentityUpdate" = google_service_account.privesc44_workload_identity_update[0].email } : {},
    var.enable_privesc45 ? { "privesc45-orgPolicySet" = google_service_account.privesc45_org_policy[0].email } : {},
  )
}

# Cloud Run SA emails for Artifact Registry access
output "privesc18_sa_email" {
  description = "Email of privesc18 SA (if enabled)"
  value       = var.enable_privesc18 ? google_service_account.privesc18_actas_cloudrun[0].email : null
}

output "privesc19_sa_email" {
  description = "Email of privesc19 SA (if enabled)"
  value       = var.enable_privesc19 ? google_service_account.privesc19_run_update[0].email : null
}

output "privesc20_sa_email" {
  description = "Email of privesc20 SA (if enabled)"
  value       = var.enable_privesc20 ? google_service_account.privesc20_run_jobs[0].email : null
}

output "privesc21_sa_email" {
  description = "Email of privesc21 SA (if enabled)"
  value       = var.enable_privesc21 ? google_service_account.privesc21_run_jobs_update[0].email : null
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

# NOTE: privesc25 target job, privesc27 target deployment, and privesc29 target
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
