# GCP IAM Vulnerable Cleanup Scripts

These scripts help clean up GCP IAM Vulnerable resources when Terraform state is lost or corrupted.

## Primary Cleanup Method

The preferred method is always to use Terraform:

```bash
cd /path/to/iam-vulnerable/gcp
terraform destroy
```

## When to Use These Scripts

Use these scripts only when:
- Terraform state is lost or corrupted
- `terraform destroy` fails
- You need to clean up resources manually

## Scripts

### cleanup_iam_vulnerable.sh (Bash)

Simple bash script using gcloud CLI.

**Requirements:**
- gcloud CLI installed and configured
- Appropriate permissions (Owner or IAM Admin)

**Usage:**

```bash
# Dry run (shows what would be deleted)
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT_ID --dry-run

# Actual cleanup
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT_ID

# With custom prefix (default is "privesc")
./cleanup_iam_vulnerable.sh --project YOUR_PROJECT_ID --prefix myprefix
```

### cleanup_iam_vulnerable.py (Python)

More robust Python script with better error handling.

**Requirements:**
- Python 3.7+
- google-cloud-iam library: `pip install google-cloud-iam`
- Application Default Credentials configured

**Usage:**

```bash
# Dry run
python cleanup_iam_vulnerable.py --project YOUR_PROJECT_ID --dry-run

# Actual cleanup
python cleanup_iam_vulnerable.py --project YOUR_PROJECT_ID

# With custom prefix
python cleanup_iam_vulnerable.py --project YOUR_PROJECT_ID --prefix myprefix
```

## What Gets Cleaned Up

1. **Service Accounts** - All SAs with the configured prefix
2. **Custom IAM Roles** - All custom roles with the configured prefix
3. **IAM Policy Bindings** - Bindings referencing deleted SAs
4. **Compute Resources** (if non-free modules were enabled):
   - VM instances
   - VPC networks
   - Firewall rules
5. **Serverless Resources** (if non-free modules were enabled):
   - Cloud Functions
   - Cloud Run services
   - Storage buckets

## Safety Features

- Both scripts require explicit confirmation (unless --force is used)
- Dry run mode shows what would be deleted without making changes
- Scripts use the configured prefix to avoid deleting unrelated resources
- Resources are deleted in dependency order

## Troubleshooting

### "Permission Denied" errors

Ensure you have sufficient permissions:
- `iam.serviceAccounts.delete`
- `iam.roles.delete`
- `resourcemanager.projects.setIamPolicy`

### Some resources not deleted

Resources may have been created with different prefixes or by other tools.
Check the GCP Console IAM page for remaining resources.

### Script fails partway through

Run the script again - it will skip already-deleted resources.
