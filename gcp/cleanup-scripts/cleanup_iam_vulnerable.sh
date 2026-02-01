#!/bin/bash
#
# GCP IAM Vulnerable Cleanup Script
#
# This script cleans up resources created by GCP IAM Vulnerable when
# Terraform state is lost or corrupted.
#
# Usage:
#   ./cleanup_iam_vulnerable.sh --project PROJECT_ID [--prefix PREFIX] [--dry-run] [--force]

set -e

# Default values
PREFIX="privesc"
DRY_RUN=false
FORCE=false
PROJECT_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT_ID="$2"
            shift 2
            ;;
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --project PROJECT_ID [--prefix PREFIX] [--dry-run] [--force]"
            echo ""
            echo "Options:"
            echo "  --project    GCP project ID (required)"
            echo "  --prefix     Resource prefix to match (default: privesc)"
            echo "  --dry-run    Show what would be deleted without deleting"
            echo "  --force      Skip confirmation prompt"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PROJECT_ID" ]]; then
    echo -e "${RED}Error: --project is required${NC}"
    exit 1
fi

echo -e "${YELLOW}GCP IAM Vulnerable Cleanup${NC}"
echo "================================"
echo "Project: $PROJECT_ID"
echo "Prefix:  $PREFIX"
echo "Dry Run: $DRY_RUN"
echo ""

# Confirmation
if [[ "$FORCE" != true && "$DRY_RUN" != true ]]; then
    read -p "This will DELETE resources in project $PROJECT_ID. Continue? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 0
    fi
fi

# Function to run or simulate a command
run_cmd() {
    if [[ "$DRY_RUN" == true ]]; then
        echo -e "${YELLOW}[DRY RUN]${NC} $*"
    else
        echo -e "${GREEN}[RUNNING]${NC} $*"
        eval "$@" || true
    fi
}

echo ""
echo -e "${YELLOW}=== Cleaning up Service Accounts ===${NC}"

# List and delete service accounts matching prefix
SERVICE_ACCOUNTS=$(gcloud iam service-accounts list \
    --project="$PROJECT_ID" \
    --format="value(email)" \
    --filter="email:${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$SERVICE_ACCOUNTS" ]]; then
    while IFS= read -r sa; do
        if [[ -n "$sa" ]]; then
            run_cmd "gcloud iam service-accounts delete '$sa' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$SERVICE_ACCOUNTS"
else
    echo "No service accounts found matching prefix: $PREFIX"
fi

# Also check for test-* service accounts
TEST_ACCOUNTS=$(gcloud iam service-accounts list \
    --project="$PROJECT_ID" \
    --format="value(email)" \
    --filter="email:test-*" 2>/dev/null || echo "")

if [[ -n "$TEST_ACCOUNTS" ]]; then
    echo ""
    echo -e "${YELLOW}=== Cleaning up Test Service Accounts ===${NC}"
    while IFS= read -r sa; do
        if [[ -n "$sa" ]]; then
            run_cmd "gcloud iam service-accounts delete '$sa' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$TEST_ACCOUNTS"
fi

echo ""
echo -e "${YELLOW}=== Cleaning up Custom IAM Roles ===${NC}"

# List and delete custom roles matching prefix
CUSTOM_ROLES=$(gcloud iam roles list \
    --project="$PROJECT_ID" \
    --format="value(name)" \
    --filter="name:${PREFIX}_*" 2>/dev/null || echo "")

if [[ -n "$CUSTOM_ROLES" ]]; then
    while IFS= read -r role; do
        if [[ -n "$role" ]]; then
            # Extract role ID from full path
            role_id=$(echo "$role" | sed 's|.*roles/||')
            run_cmd "gcloud iam roles delete '$role_id' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$CUSTOM_ROLES"
else
    echo "No custom roles found matching prefix: ${PREFIX}_"
fi

echo ""
echo -e "${YELLOW}=== Cleaning up Compute Resources ===${NC}"

# Delete VM instances
INSTANCES=$(gcloud compute instances list \
    --project="$PROJECT_ID" \
    --format="value(name,zone)" \
    --filter="name:${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$INSTANCES" ]]; then
    while IFS=$'\t' read -r name zone; do
        if [[ -n "$name" && -n "$zone" ]]; then
            run_cmd "gcloud compute instances delete '$name' --zone='$zone' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$INSTANCES"
else
    echo "No compute instances found matching prefix: $PREFIX"
fi

# Delete firewall rules
FIREWALLS=$(gcloud compute firewall-rules list \
    --project="$PROJECT_ID" \
    --format="value(name)" \
    --filter="name:${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$FIREWALLS" ]]; then
    while IFS= read -r fw; do
        if [[ -n "$fw" ]]; then
            run_cmd "gcloud compute firewall-rules delete '$fw' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$FIREWALLS"
fi

# Delete VPC networks (subnets are deleted automatically)
NETWORKS=$(gcloud compute networks list \
    --project="$PROJECT_ID" \
    --format="value(name)" \
    --filter="name:${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$NETWORKS" ]]; then
    while IFS= read -r net; do
        if [[ -n "$net" ]]; then
            # First delete subnets
            SUBNETS=$(gcloud compute networks subnets list \
                --project="$PROJECT_ID" \
                --network="$net" \
                --format="value(name,region)" 2>/dev/null || echo "")
            while IFS=$'\t' read -r subnet region; do
                if [[ -n "$subnet" && -n "$region" ]]; then
                    run_cmd "gcloud compute networks subnets delete '$subnet' --region='$region' --project='$PROJECT_ID' --quiet"
                fi
            done <<< "$SUBNETS"

            run_cmd "gcloud compute networks delete '$net' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$NETWORKS"
fi

echo ""
echo -e "${YELLOW}=== Cleaning up Cloud Functions ===${NC}"

FUNCTIONS=$(gcloud functions list \
    --project="$PROJECT_ID" \
    --format="value(name,region)" \
    --filter="name:${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$FUNCTIONS" ]]; then
    while IFS=$'\t' read -r name region; do
        if [[ -n "$name" && -n "$region" ]]; then
            run_cmd "gcloud functions delete '$name' --region='$region' --project='$PROJECT_ID' --quiet"
        fi
    done <<< "$FUNCTIONS"
else
    echo "No Cloud Functions found matching prefix: $PREFIX"
fi

echo ""
echo -e "${YELLOW}=== Cleaning up Cloud Run Services ===${NC}"

# Get all regions with Cloud Run services
REGIONS=$(gcloud run regions list --format="value(name)" 2>/dev/null || echo "us-central1")

for region in $REGIONS; do
    SERVICES=$(gcloud run services list \
        --project="$PROJECT_ID" \
        --region="$region" \
        --format="value(name)" \
        --filter="name:${PREFIX}*" 2>/dev/null || echo "")

    if [[ -n "$SERVICES" ]]; then
        while IFS= read -r svc; do
            if [[ -n "$svc" ]]; then
                run_cmd "gcloud run services delete '$svc' --region='$region' --project='$PROJECT_ID' --quiet"
            fi
        done <<< "$SERVICES"
    fi
done

echo ""
echo -e "${YELLOW}=== Cleaning up Storage Buckets ===${NC}"

BUCKETS=$(gcloud storage buckets list \
    --project="$PROJECT_ID" \
    --format="value(name)" \
    --filter="name:*${PREFIX}*" 2>/dev/null || echo "")

if [[ -n "$BUCKETS" ]]; then
    while IFS= read -r bucket; do
        if [[ -n "$bucket" ]]; then
            run_cmd "gcloud storage rm -r 'gs://$bucket' --project='$PROJECT_ID'"
        fi
    done <<< "$BUCKETS"
else
    echo "No storage buckets found matching prefix: $PREFIX"
fi

echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Dry run complete. No resources were modified.${NC}"
else
    echo -e "${GREEN}Cleanup complete!${NC}"
fi
