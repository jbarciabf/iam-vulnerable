# GCP Privesc Paths Module - Outputs

output "high_priv_service_account_email" {
  description = "Email of the high-privilege (Owner) service account - escalation target"
  value       = google_service_account.high_priv.email
}

output "medium_priv_service_account_email" {
  description = "Email of the medium-privilege (Editor) service account"
  value       = google_service_account.medium_priv.email
}

output "privesc_service_accounts" {
  description = "Map of privesc path names to their service account emails"
  value = {
    "privesc1-setIamPolicy-project"        = google_service_account.privesc1_set_iam_policy.email
    "privesc2-createServiceAccountKey"     = google_service_account.privesc2_create_key.email
    "privesc3-setIamPolicy-serviceAccount" = google_service_account.privesc3_set_sa_iam.email
    "privesc4-actAs-compute"               = google_service_account.privesc4_actas_compute.email
    "privesc5-actAs-cloudfunction"         = google_service_account.privesc5_actas_function.email
    "privesc6-actAs-cloudrun"              = google_service_account.privesc6_actas_cloudrun.email
    "privesc7-actAs-cloudbuild"            = google_service_account.privesc7_actas_cloudbuild.email
    "privesc8-getAccessToken"              = google_service_account.privesc8_get_access_token.email
    "privesc9-signBlob"                    = google_service_account.privesc9_sign_blob.email
    "privesc10-signJwt"                    = google_service_account.privesc10_sign_jwt.email
    "privesc11-updateRole"                 = google_service_account.privesc11_update_role.email
    "privesc12-setMetadata-compute"        = google_service_account.privesc12_set_metadata.email
    "privesc13-osLogin"                    = google_service_account.privesc13_os_login.email
    "privesc14-setIamPolicy-bucket"        = google_service_account.privesc14_bucket_iam.email
    "privesc15-updateFunction"             = google_service_account.privesc15_update_function.email
    "privesc16-explicitDeny-bypass"        = google_service_account.privesc16_deny_bypass.email
    "privesc17-deploymentManager"          = google_service_account.privesc17_deployment_manager.email
    "privesc18-composer"                   = google_service_account.privesc18_composer.email
    "privesc19-dataflow"                   = google_service_account.privesc19_dataflow.email
    "privesc20-secretManager"              = google_service_account.privesc20_secret_access.email
    "privesc21-setIamPolicy-pubsub"        = google_service_account.privesc21_pubsub_iam.email
    "privesc22-cloudScheduler"             = google_service_account.privesc22_scheduler.email
  }
}

output "vulnerable_custom_roles" {
  description = "List of vulnerable custom roles created"
  value = [
    google_project_iam_custom_role.set_iam_policy.id,
    google_project_iam_custom_role.create_sa_key.id,
    google_project_iam_custom_role.set_sa_iam_policy.id,
    google_project_iam_custom_role.sign_blob.id,
    google_project_iam_custom_role.sign_jwt.id,
    google_project_iam_custom_role.modifiable_role.id,
    google_project_iam_custom_role.set_metadata.id,
    google_project_iam_custom_role.bucket_iam.id,
    google_project_iam_custom_role.update_function.id,
    google_project_iam_custom_role.composer.id,
    google_project_iam_custom_role.pubsub_iam.id,
    google_project_iam_custom_role.scheduler.id,
  ]
}
