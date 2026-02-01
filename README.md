
# IAM Vulnerable

Use Terraform to create your own *vulnerable by design* cloud IAM privilege escalation playground.

![](.images/IAMVulnerable-350px.png)

IAM Vulnerable uses Terraform and your cloud credentials to deploy intentionally vulnerable IAM configurations. Within minutes, you can start learning how to identify and exploit vulnerable IAM configurations that allow for privilege escalation.

## Supported Cloud Platforms

| Cloud | Directory | Privilege Escalation Paths | Status |
|-------|-----------|---------------------------|--------|
| **AWS** | [`aws/`](aws/) | 31 paths | Production |
| **GCP** | [`gcp/`](gcp/) | 31 paths | Production |

## Quick Start

### Choose Your Cloud

```bash
# Clone the repository
git clone https://github.com/BishopFox/iam-vulnerable
cd iam-vulnerable

# For AWS
cd aws
terraform init && terraform apply

# For GCP
cd gcp
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your project ID
terraform init && terraform apply
```

### AWS Quick Start

1. Select or create an AWS account (Do NOT use an account with production resources!)
2. [Create a non-root user with administrative access](https://docs.aws.amazon.com/IAM/latest/UserGuide/getting-started_create-admin-group.html)
3. [Configure your AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with the admin user
4. Deploy:
   ```bash
   cd aws
   terraform init
   terraform apply
   ```

### GCP Quick Start

1. Select or create a GCP project (Do NOT use a project with production resources!)
2. Set up authentication and enable the Service Usage API (required for Terraform to enable other APIs):
   ```bash
   # Authenticate with GCP
   gcloud auth login
   gcloud auth application-default login

   # Set your project
   export PROJECT_ID="your-test-project-id"
   gcloud config set project $PROJECT_ID

   # Enable Service Usage API (Terraform will enable the rest automatically)
   gcloud services enable serviceusage.googleapis.com --project $PROJECT_ID
   ```
3. Deploy:
   ```bash
   cd gcp
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars and set your project ID
   terraform init
   terraform apply
   ```

**Note:** Terraform automatically enables these APIs: IAM, Cloud Resource Manager, Compute, Cloud Functions, Cloud Build, Cloud Run, Storage, and Secret Manager.

# IAM Vulnerable's big brother - CloudFoxable

Hey all. IAM Vulnerable is still immensely useful for understanding the basic building blocks of cloud IAM privilege escalation. However, a few years after making IAM vulnerable, I created CloudFoxable, a CTF style version that teaches you the basics of cloud penetration testing more wholistically. - [@sethsec](https://www.linkedin.com/in/sethart/)

#### Intentionally Vulnerable Playground
* [CloudFoxable - A Gamified Cloud Hacking Sandbox](https://cloudfoxable.bishopfox.com/)

#### Want to chat about IAM-Vulnerable, CloudFox, and CloudFoxable?
Join us on the [RedSec discord server](https://discord.gg/redsec)

# Table of Contents

- [AWS Privilege Escalation Paths](#aws-privilege-escalation-paths)
- [GCP Privilege Escalation Paths](#gcp-privilege-escalation-paths)
- [Cost Information](#cost-information)
- [Tool Testing](#tool-testing)
- [Cleanup](#cleanup)
- [FAQ](#faq)

# AWS Privilege Escalation Paths

:fox_face: **AWS paths: 31**

See [aws/README.md](aws/) for detailed AWS documentation.

| Category | Path Name | Description |
|----------|-----------|-------------|
| **IAM Permissions on Other Users** | | |
| | IAM-CreateAccessKey | Create access key for another user |
| | IAM-CreateLoginProfile | Create console login for another user |
| | IAM-UpdateLoginProfile | Update another user's console password |
| **PassRole to Service** | | |
| | CloudFormation-PassExistingRoleToCloudFormation | Pass role to CloudFormation |
| | CodeBuild-CreateProjectPassRole | Pass role to CodeBuild |
| | DataPipeline-PassExistingRoleToNewDataPipeline | Pass role to Data Pipeline |
| | EC2-CreateInstanceWithExistingProfile | Create EC2 with privileged instance profile |
| | Glue-PassExistingRoleToNewGlueDevEndpoint | Pass role to Glue |
| | Lambda-PassExistingRoleToNewLambdaThenInvoke | Pass role to Lambda |
| | Lambda-PassRoleToNewLambdaThenTrigger | Pass role to Lambda with trigger |
| | SageMaker-CreateNotebookPassRole | Pass role to SageMaker notebook |
| | SageMaker-CreateTrainingJobPassRole | Pass role to SageMaker training |
| | SageMaker-CreateProcessingJobPassRole | Pass role to SageMaker processing |
| **Permissions on Policies** | | |
| | IAM-AddUserToGroup | Add self to admin group |
| | IAM-AttachGroupPolicy | Attach policy to group |
| | IAM-AttachRolePolicy | Attach policy to role |
| | IAM-AttachUserPolicy | Attach policy to user |
| | IAM-CreateNewPolicyVersion | Create new policy version |
| | IAM-PutGroupPolicy | Put inline policy on group |
| | IAM-PutRolePolicy | Put inline policy on role |
| | IAM-PutUserPolicy | Put inline policy on user |
| | IAM-SetExistingDefaultPolicyVersion | Set default policy version |
| **AWS Service Escalation** | | |
| | EC2InstanceConnect-SendSSHPublicKey | SSH via EC2 Instance Connect |
| | CloudFormation-UpdateStack | Update CloudFormation stack |
| | Glue-UpdateExistingGlueDevEndpoint | Update Glue endpoint |
| | Lambda-EditExistingLambdaFunctionWithRole | Edit Lambda function code |
| | SageMakerCreatePresignedNotebookURL | Get SageMaker presigned URL |
| | SSM-SendCommand | Send SSM command |
| | SSM-StartSession | Start SSM session |
| | STS-AssumeRole | Assume privileged role |
| **AssumeRole Policy** | | |
| | IAM-UpdatingAssumeRolePolicy | Update role trust policy |

# GCP Privilege Escalation Paths

:cloud: **GCP paths: 31**

See [gcp/README.md](gcp/) for detailed GCP documentation.

| # | Path Name | Vulnerable Permission | Description |
|---|-----------|----------------------|-------------|
| 1 | setIamPolicy-project | `resourcemanager.projects.setIamPolicy` | Grant self Owner role |
| 2 | createServiceAccountKey | `iam.serviceAccountKeys.create` | Create key for privileged SA |
| 3 | setIamPolicy-serviceAccount | `iam.serviceAccounts.setIamPolicy` | Grant self actAs on privileged SA |
| 4 | actAs-compute | `iam.serviceAccounts.actAs` + `compute.instances.create` | Create VM as privileged SA |
| 5 | actAs-cloudfunction | `actAs` + `cloudfunctions.functions.create` | Deploy function as privileged SA |
| 6 | actAs-cloudrun | `actAs` + `run.services.create` | Deploy Cloud Run as privileged SA |
| 7 | actAs-cloudbuild | `actAs` + `cloudbuild.builds.create` | Run build as privileged SA |
| 8 | getAccessToken | `iam.serviceAccounts.getAccessToken` | Generate token for privileged SA |
| 9 | signBlob | `iam.serviceAccounts.signBlob` | Sign data as privileged SA |
| 10 | signJwt | `iam.serviceAccounts.signJwt` | Sign JWT as privileged SA |
| 11 | updateRole | `iam.roles.update` | Add permissions to custom role |
| 12 | setMetadata-compute | `compute.instances.setMetadata` | Add SSH key to instance |
| 13 | osLogin | `compute.instances.osAdminLogin` | SSH via OS Login |
| 14 | setIamPolicy-bucket | `storage.buckets.setIamPolicy` | Grant access to buckets |
| 15 | updateFunction | `cloudfunctions.functions.update` | Modify function code |
| 16 | explicitDeny-bypass | SA chaining | Bypass deny via SA impersonation |
| 17 | deploymentManager | `deploymentmanager.deployments.create` | Deploy infra as privileged SA |
| 18 | composer | `composer.environments.create` | Create Composer as privileged SA |
| 19 | dataflow | `dataflow.jobs.create` | Run Dataflow as privileged SA |
| 20 | secretManager | `secretmanager.versions.access` | Access secrets directly |
| 21 | setIamPolicy-pubsub | `pubsub.topics.setIamPolicy` | Modify Pub/Sub access |
| 22 | cloudScheduler | `cloudscheduler.jobs.create` | Create scheduler with SA identity |
| 23 | implicitDelegation | `iam.serviceAccounts.implicitDelegation` | Multi-hop impersonation chain |
| 24 | getOpenIdToken | `iam.serviceAccounts.getOpenIdToken` | Generate OIDC tokens for services |
| 25 | setServiceAccount | `compute.instances.setServiceAccount` | Change VM's service account |
| 26 | instanceTemplates | `compute.instanceTemplates.create` | Create templates with priv SA |
| 27 | runJobsCreate | `run.jobs.create` + `actAs` | Create Cloud Run job as priv SA |
| 28 | dataprocClusters | `dataproc.clusters.create` + `actAs` | Create Dataproc as priv SA |
| 29 | gkeCluster | `container.clusters.create` + `actAs` | Create GKE cluster as priv SA |
| 30 | notebooksInstances | `notebooks.instances.create` + `actAs` | Create Vertex AI notebook |
| 31 | workflows | `workflows.workflows.create` + `actAs` | Create workflow as priv SA |

# Cost Information

## AWS Cost

| Module | Default | Cost | Required For |
|--------|---------|------|--------------|
| privesc-paths | Enabled | **Free** | All IAM paths |
| tool-testing | Enabled | **Free** | Tool validation |
| EC2 | Disabled | ~$4.50/mo | SSM, EC2 Instance Connect |
| Lambda | Disabled | Free tier | Lambda code editing |
| Glue | Disabled | ~$4/hr | Glue endpoint update |
| SageMaker | Disabled | Varies | SageMaker presigned URL |
| CloudFormation | Disabled | ~$0.40/mo | CF stack update |

## GCP Cost

| Module | Default | Variable to Enable | Cost/Month | Required For |
|--------|---------|-------------------|------------|--------------|
| privesc-paths (31) | Enabled | Always on | **Free** | All IAM paths |
| tool-testing | Enabled | Always on | **Free** | Tool validation |
| Compute | Disabled | `enable_compute = true` | ~$2-3 | setMetadata, osLogin |
| Cloud Functions | Disabled | `enable_cloud_functions = true` | Free tier | updateFunction |
| Cloud Run | Disabled | `enable_cloud_run = true` | Free tier | actAs-cloudrun |

**Default deployment: $0** (IAM resources only)

Enable optional modules in `terraform.tfvars`:
```hcl
enable_compute         = true  # Add VM for hands-on testing
enable_cloud_functions = true  # Add Cloud Function
enable_cloud_run       = true  # Add Cloud Run service
```

# Tool Testing

Both AWS and GCP modules include test cases to validate detection tools:

**False Negative Tests** - Paths that SHOULD be detected:
- Exploitable conditions that appear restrictive but aren't
- Indirect access via groups
- Multi-hop escalation chains

**False Positive Tests** - Paths that should NOT be flagged:
- Truly restrictive conditions
- Explicit deny policies
- Scope-limited permissions
- No viable targets

Test your tools:
```bash
# AWS
cd aws && terraform apply
pmapper graph create
pmapper analysis

# GCP
cd gcp && terraform apply
foxmapper gcp graph create --project YOUR_PROJECT
foxmapper gcp argquery --preset privesc --project YOUR_PROJECT
```

# Cleanup

## AWS Cleanup

```bash
cd aws
terraform destroy
```

If Terraform state is lost:
```bash
cd aws/cleanup-scripts
./cleanup_iam_vulnerable.sh --dry-run  # Preview
./cleanup_iam_vulnerable.sh            # Execute
```

## GCP Cleanup

```bash
cd gcp
terraform destroy
```

If Terraform state is lost:
```bash
cd gcp/cleanup-scripts
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT --dry-run  # Preview
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT            # Execute
```

# FAQ

### How does IAM Vulnerable compare to CloudGoat, Terragoat, and SadCloud?

All of these tools use Terraform to deploy intentionally vulnerable infrastructure. However, **IAM Vulnerable's focus is IAM privilege escalation**, whereas the other tools either don't cover IAM privesc or only cover some scenarios.

### Can I run AWS and GCP simultaneously?

Yes! Each cloud platform has its own directory with separate Terraform state. Deploy both for a comprehensive multi-cloud privilege escalation lab.

### I'm new to Terraform. Is this safe?

Yes, if you follow these guidelines:
- Use an isolated test account/project with no production resources
- Run `terraform plan` first to preview changes
- Use `terraform destroy` to clean up
- Check out [Infracost](https://www.infracost.io/) to estimate costs before deploying

### What tools can I use to practice?

**AWS:**
- [Cloudsplaining](https://github.com/salesforce/cloudsplaining/)
- [AWSPX](https://github.com/FSecureLABS/awspx)
- [Principal Mapper (PMapper)](https://github.com/nccgroup/PMapper)
- [Pacu](https://github.com/RhinoSecurityLabs/pacu)
- [FoxMapper](https://github.com/BishopFox/foxmapper)

**GCP:**
- [FoxMapper](https://github.com/BishopFox/foxmapper)
- [gcpwn](https://github.com/NetSPI/gcpwn)

# Prior Work and References

* https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/
* https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation-part-2/
* https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws
* https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/
* https://cloud.google.com/iam/docs/understanding-roles
