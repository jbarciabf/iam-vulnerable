#!/bin/bash
# cleanup-project.sh - Enumerate and delete all iam-vulnerable resources
# Usage: ./cleanup-project.sh <PROJECT_ID>
#
# This script uses gcloud to find and delete resources that may incur costs.
# Run this before deleting your project to ensure no orphaned resources remain.

set -e

PROJECT_ID="${1:-$PROJECT_ID}"
if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 <PROJECT_ID>"
    echo "   or: PROJECT_ID=your-project-id $0"
    exit 1
fi

echo "=== Cleaning up project: $PROJECT_ID ==="
echo ""
echo "WARNING: This will DELETE ALL RESOURCES in the project!"
echo "This action is IRREVERSIBLE and may result in data loss."
echo ""
echo "Type 'DELETE' to confirm: "
read confirmation
if [ "$confirmation" != "DELETE" ]; then
    echo "Aborted. You must type 'DELETE' to confirm."
    exit 1
fi

# Enable Cloud Asset API if not already enabled
echo "Enabling Cloud Asset API..."
gcloud services enable cloudasset.googleapis.com --project=$PROJECT_ID 2>/dev/null || true

echo ""
echo "=== Step 1: Delete Composer Environments (most expensive - ~\$400/mo) ==="
gcloud composer environments list --locations=- --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read env; do
    if [ -n "$env" ]; then
        echo "Deleting Composer environment: $env"
        gcloud composer environments delete "$env" --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 2: Delete Compute Instances ==="
gcloud compute instances list --project=$PROJECT_ID --format="value(name,zone)" 2>/dev/null | while read name zone; do
    if [ -n "$name" ]; then
        echo "Deleting instance: $name in $zone"
        gcloud compute instances delete "$name" --zone="$zone" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 3: Delete GKE Clusters ==="
gcloud container clusters list --project=$PROJECT_ID --format="value(name,location)" 2>/dev/null | while read name location; do
    if [ -n "$name" ]; then
        echo "Deleting GKE cluster: $name in $location"
        gcloud container clusters delete "$name" --location="$location" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 4: Delete Cloud Run Services ==="
gcloud run services list --project=$PROJECT_ID --format="value(metadata.name,region)" 2>/dev/null | while read name region; do
    if [ -n "$name" ]; then
        echo "Deleting Cloud Run service: $name in $region"
        gcloud run services delete "$name" --region="$region" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 5: Delete Cloud Run Jobs ==="
gcloud run jobs list --project=$PROJECT_ID --format="value(metadata.name,region)" 2>/dev/null | while read name region; do
    if [ -n "$name" ]; then
        echo "Deleting Cloud Run job: $name in $region"
        gcloud run jobs delete "$name" --region="$region" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 6: Delete Cloud Functions (Gen 1 and Gen 2) ==="
# Gen 2 functions
gcloud functions list --project=$PROJECT_ID --gen2 --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        echo "Deleting Gen2 function: $name"
        gcloud functions delete "$name" --project=$PROJECT_ID --gen2 --quiet 2>/dev/null || true
    fi
done
# Gen 1 functions
gcloud functions list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        echo "Deleting Gen1 function: $name"
        gcloud functions delete "$name" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 7: Delete Dataproc Clusters ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud dataproc clusters list --project=$PROJECT_ID --region=$region --format="value(clusterName)" 2>/dev/null | while read name; do
        if [ -n "$name" ]; then
            echo "Deleting Dataproc cluster: $name in $region"
            gcloud dataproc clusters delete "$name" --region="$region" --project=$PROJECT_ID --quiet 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 8: Delete Dataflow Jobs ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud dataflow jobs list --project=$PROJECT_ID --region=$region --status=active --format="value(id)" 2>/dev/null | while read id; do
        if [ -n "$id" ]; then
            echo "Cancelling Dataflow job: $id in $region"
            gcloud dataflow jobs cancel "$id" --region=$region --project=$PROJECT_ID 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 9: Delete Notebooks Instances ==="
gcloud notebooks instances list --project=$PROJECT_ID --format="value(name,location)" 2>/dev/null | while read name location; do
    if [ -n "$name" ]; then
        echo "Deleting notebook: $name in $location"
        gcloud notebooks instances delete "$name" --location="$location" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 10: Delete AI Platform / Vertex AI Custom Jobs ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud ai custom-jobs list --project=$PROJECT_ID --region=$region --format="value(name)" 2>/dev/null | while read name; do
        if [ -n "$name" ]; then
            echo "Cancelling AI job: $name"
            gcloud ai custom-jobs cancel "$name" --region=$region --project=$PROJECT_ID 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 11: Delete Cloud Scheduler Jobs ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud scheduler jobs list --project=$PROJECT_ID --location=$region --format="value(name)" 2>/dev/null | while read name; do
        if [ -n "$name" ]; then
            # Extract just the job name from the full path
            job_name=$(basename "$name")
            echo "Deleting scheduler job: $job_name in $region"
            gcloud scheduler jobs delete "$job_name" --location=$region --project=$PROJECT_ID --quiet 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 12: Delete Workflows ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud workflows list --project=$PROJECT_ID --location=$region --format="value(name)" 2>/dev/null | while read name; do
        if [ -n "$name" ]; then
            workflow_name=$(basename "$name")
            echo "Deleting workflow: $workflow_name in $region"
            gcloud workflows delete "$workflow_name" --location=$region --project=$PROJECT_ID --quiet 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 13: Delete Eventarc Triggers ==="
for region in us-central1 us-east1 us-west1 europe-west1; do
    gcloud eventarc triggers list --project=$PROJECT_ID --location=$region --format="value(name)" 2>/dev/null | while read name; do
        if [ -n "$name" ]; then
            trigger_name=$(basename "$name")
            echo "Deleting trigger: $trigger_name in $region"
            gcloud eventarc triggers delete "$trigger_name" --location=$region --project=$PROJECT_ID --quiet 2>/dev/null || true
        fi
    done
done

echo ""
echo "=== Step 14: Delete Deployment Manager Deployments ==="
gcloud deployment-manager deployments list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        echo "Deleting deployment: $name"
        gcloud deployment-manager deployments delete "$name" --project=$PROJECT_ID --quiet --delete-policy=DELETE 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 15: Delete Workload Identity Pools ==="
gcloud iam workload-identity-pools list --project=$PROJECT_ID --location=global --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        pool_name=$(basename "$name")
        echo "Deleting workload identity pool: $pool_name"
        gcloud iam workload-identity-pools delete "$pool_name" --location=global --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 16: Delete GCS Buckets (empties and removes) ==="
gsutil ls -p $PROJECT_ID 2>/dev/null | while read bucket; do
    if [ -n "$bucket" ]; then
        echo "Deleting bucket: $bucket"
        gsutil -m rm -r "$bucket" 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 17: Delete Artifact Registry Repositories ==="
gcloud artifacts repositories list --project=$PROJECT_ID --format="value(name,location)" 2>/dev/null | while read name location; do
    if [ -n "$name" ]; then
        echo "Deleting artifact repository: $name in $location"
        gcloud artifacts repositories delete "$name" --location="$location" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 18: Delete Pub/Sub Subscriptions ==="
gcloud pubsub subscriptions list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        sub_name=$(basename "$name")
        echo "Deleting subscription: $sub_name"
        gcloud pubsub subscriptions delete "$sub_name" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 19: Delete Pub/Sub Topics ==="
gcloud pubsub topics list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        topic_name=$(basename "$name")
        echo "Deleting topic: $topic_name"
        gcloud pubsub topics delete "$topic_name" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 20: Delete BigQuery Datasets ==="
bq ls --project_id=$PROJECT_ID --format=sparse 2>/dev/null | tail -n +3 | while read dataset; do
    if [ -n "$dataset" ]; then
        echo "Deleting BigQuery dataset: $dataset"
        bq rm -r -f --project_id=$PROJECT_ID "$dataset" 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 21: Delete Secret Manager Secrets ==="
gcloud secrets list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read name; do
    if [ -n "$name" ]; then
        echo "Deleting secret: $name"
        gcloud secrets delete "$name" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 22: Delete Service Account Keys (user-managed only) ==="
gcloud iam service-accounts list --project=$PROJECT_ID --format="value(email)" 2>/dev/null | while read sa; do
    if [ -n "$sa" ]; then
        gcloud iam service-accounts keys list --iam-account="$sa" --managed-by=user --format="value(name)" 2>/dev/null | while read key; do
            if [ -n "$key" ]; then
                key_id=$(basename "$key")
                echo "Deleting key $key_id from $sa"
                gcloud iam service-accounts keys delete "$key_id" --iam-account="$sa" --project=$PROJECT_ID --quiet 2>/dev/null || true
            fi
        done
    fi
done

echo ""
echo "=== Step 23: Delete Custom IAM Roles ==="
gcloud iam roles list --project=$PROJECT_ID --format="value(name)" 2>/dev/null | while read role; do
    if [ -n "$role" ]; then
        role_id=$(basename "$role")
        echo "Deleting role: $role_id"
        gcloud iam roles delete "$role_id" --project=$PROJECT_ID --quiet 2>/dev/null || true
    fi
done

echo ""
echo "=== Step 24: Delete Service Accounts (user-created only) ==="
gcloud iam service-accounts list --project=$PROJECT_ID --format="value(email)" 2>/dev/null | \
    grep -v "@cloudservices.gserviceaccount.com" | \
    grep -v "compute@developer.gserviceaccount.com" | \
    grep -v "@appspot.gserviceaccount.com" | \
    while read sa; do
        if [ -n "$sa" ]; then
            echo "Deleting service account: $sa"
            gcloud iam service-accounts delete "$sa" --project=$PROJECT_ID --quiet 2>/dev/null || true
        fi
    done

echo ""
echo "=== Step 25: List Remaining Resources via Asset Inventory ==="
echo "Checking for any remaining resources..."
gcloud asset search-all-resources --scope=projects/$PROJECT_ID --format="table(assetType,name)" 2>/dev/null | head -50 || true

echo ""
echo "=========================================="
echo "=== Cleanup Complete ==="
echo "=========================================="
echo ""
echo "To fully delete the project (recommended):"
echo "  gcloud projects delete $PROJECT_ID --quiet"
echo ""
echo "Note: Some resources (like custom IAM roles) have a 7-day soft-delete period."
echo "Deleting the project is the only way to immediately free all resources."
