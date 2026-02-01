# GCP Privesc Paths Module - Outputs

output "high_priv_service_account_email" {
  description = "Email of the high-privilege target service account"
  value       = google_service_account.high_priv.email
}

output "medium_priv_service_account_email" {
  description = "Email of the medium-privilege service account"
  value       = google_service_account.medium_priv.email
}

output "privesc_service_accounts" {
  description = "Map of all privilege escalation service account emails"
  value = {
    # IAM Service Account (1-9)
    "privesc1-setIamPolicy-project"       = google_service_account.privesc1_set_iam_policy.email
    "privesc2-createServiceAccountKey"    = google_service_account.privesc2_create_key.email
    "privesc3-setIamPolicy-serviceAccount" = google_service_account.privesc3_set_sa_iam.email
    "privesc4-getAccessToken"             = google_service_account.privesc4_get_access_token.email
    "privesc5-signBlob"                   = google_service_account.privesc5_sign_blob.email
    "privesc6-signJwt"                    = google_service_account.privesc6_sign_jwt.email
    "privesc7-implicitDelegation"         = google_service_account.privesc7_implicit_delegation.email
    "privesc8-getOpenIdToken"             = google_service_account.privesc8_get_oidc_token.email
    "privesc9-updateRole"                 = google_service_account.privesc9_update_role.email

    # Compute Engine (10-14)
    "privesc10-actAs-compute"             = google_service_account.privesc10_actas_compute.email
    "privesc11-setMetadata-compute"       = google_service_account.privesc11_set_metadata.email
    "privesc12-osLogin"                   = google_service_account.privesc12_os_login.email
    "privesc13-setServiceAccount"         = google_service_account.privesc13_set_sa.email
    "privesc14-instanceTemplates"         = google_service_account.privesc14_instance_templates.email

    # Cloud Functions (15-17)
    "privesc15-actAs-cloudfunction"       = google_service_account.privesc15_actas_function.email
    "privesc16-updateFunction"            = google_service_account.privesc16_update_function.email
    "privesc17-sourceCodeSet"             = google_service_account.privesc17_source_code_set.email

    # Cloud Run (18-20)
    "privesc18-actAs-cloudrun"            = google_service_account.privesc18_actas_cloudrun.email
    "privesc19-runServicesUpdate"         = google_service_account.privesc19_run_update.email
    "privesc20-runJobsCreate"             = google_service_account.privesc20_run_jobs.email

    # Cloud Build (21-22)
    "privesc21-actAs-cloudbuild"          = google_service_account.privesc21_actas_cloudbuild.email
    "privesc22-cloudbuildTriggersCreate"  = google_service_account.privesc22_triggers.email

    # Storage (23-24)
    "privesc23-setIamPolicy-bucket"       = google_service_account.privesc23_bucket_iam.email
    "privesc24-storageObjectsCreate"      = google_service_account.privesc24_storage_write.email

    # Secret Manager (25-26)
    "privesc25-secretManager"             = google_service_account.privesc25_secret_access.email
    "privesc26-secretManagerSetIamPolicy" = google_service_account.privesc26_secret_set_iam.email

    # Pub/Sub (27)
    "privesc27-setIamPolicy-pubsub"       = google_service_account.privesc27_pubsub_iam.email

    # Cloud Scheduler (28)
    "privesc28-cloudScheduler"            = google_service_account.privesc28_scheduler.email

    # Deployment Manager (29)
    "privesc29-deploymentManager"         = google_service_account.privesc29_deployment_manager.email

    # Composer (30)
    "privesc30-composer"                  = google_service_account.privesc30_composer.email

    # Dataflow (31)
    "privesc31-dataflow"                  = google_service_account.privesc31_dataflow.email

    # Dataproc (32-33)
    "privesc32-dataprocClusters"          = google_service_account.privesc32_dataproc.email
    "privesc33-dataprocJobsCreate"        = google_service_account.privesc33_dataproc_jobs.email

    # GKE/Kubernetes (34-35)
    "privesc34-gkeCluster"                = google_service_account.privesc34_gke.email
    "privesc35-gkeGetCredentials"         = google_service_account.privesc35_gke_creds.email

    # Vertex AI / AI Platform (36-37)
    "privesc36-notebooksInstances"        = google_service_account.privesc36_notebooks.email
    "privesc37-aiplatformCustomJobs"      = google_service_account.privesc37_aiplatform.email

    # Cloud Workflows (38)
    "privesc38-workflows"                 = google_service_account.privesc38_workflows.email

    # Eventarc (39)
    "privesc39-eventarcTriggersCreate"    = google_service_account.privesc39_eventarc.email

    # BigQuery (40)
    "privesc40-bigquerySetIamPolicy"      = google_service_account.privesc40_bigquery.email

    # Workload Identity (41)
    "privesc41-workloadIdentity"          = google_service_account.privesc41_workload_identity.email

    # Org Policy (42)
    "privesc42-orgPolicySet"              = google_service_account.privesc42_org_policy.email

    # Deny Bypass (43)
    "privesc43-explicitDeny-bypass"       = google_service_account.privesc43_deny_bypass.email
  }
}
