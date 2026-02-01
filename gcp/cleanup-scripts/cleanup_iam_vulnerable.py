#!/usr/bin/env python3
"""
GCP IAM Vulnerable Cleanup Script

This script cleans up resources created by GCP IAM Vulnerable when
Terraform state is lost or corrupted.

Requirements:
    pip install google-cloud-iam google-cloud-resource-manager google-cloud-compute

Usage:
    python cleanup_iam_vulnerable.py --project PROJECT_ID [--prefix PREFIX] [--dry-run] [--force]
"""

import argparse
import sys

try:
    from google.cloud import iam_admin_v1
    from google.cloud import resourcemanager_v3
    from google.cloud import compute_v1
    from google.api_core import exceptions as gcp_exceptions
except ImportError:
    print("Required libraries not installed. Run:")
    print("  pip install google-cloud-iam google-cloud-resource-manager google-cloud-compute")
    sys.exit(1)


class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'


def log_info(msg):
    print(f"{Colors.GREEN}[INFO]{Colors.NC} {msg}")


def log_warn(msg):
    print(f"{Colors.YELLOW}[WARN]{Colors.NC} {msg}")


def log_error(msg):
    print(f"{Colors.RED}[ERROR]{Colors.NC} {msg}")


def log_dry_run(msg):
    print(f"{Colors.YELLOW}[DRY RUN]{Colors.NC} {msg}")


def cleanup_service_accounts(project_id: str, prefix: str, dry_run: bool):
    """Delete service accounts matching the prefix."""
    print(f"\n{Colors.YELLOW}=== Cleaning up Service Accounts ==={Colors.NC}")

    client = iam_admin_v1.IAMClient()
    request = iam_admin_v1.ListServiceAccountsRequest(
        name=f"projects/{project_id}"
    )

    deleted_count = 0
    try:
        for sa in client.list_service_accounts(request=request):
            # Extract email from the service account
            email = sa.email
            account_id = email.split('@')[0]

            # Check if it matches our prefix
            if account_id.startswith(prefix) or account_id.startswith('test-'):
                if dry_run:
                    log_dry_run(f"Would delete service account: {email}")
                else:
                    try:
                        delete_request = iam_admin_v1.DeleteServiceAccountRequest(
                            name=sa.name
                        )
                        client.delete_service_account(request=delete_request)
                        log_info(f"Deleted service account: {email}")
                        deleted_count += 1
                    except gcp_exceptions.NotFound:
                        log_warn(f"Service account not found (already deleted?): {email}")
                    except Exception as e:
                        log_error(f"Failed to delete {email}: {e}")
    except Exception as e:
        log_error(f"Failed to list service accounts: {e}")

    if deleted_count == 0 and not dry_run:
        print(f"No service accounts found matching prefix: {prefix}")


def cleanup_custom_roles(project_id: str, prefix: str, dry_run: bool):
    """Delete custom IAM roles matching the prefix."""
    print(f"\n{Colors.YELLOW}=== Cleaning up Custom IAM Roles ==={Colors.NC}")

    client = iam_admin_v1.IAMClient()
    request = iam_admin_v1.ListRolesRequest(
        parent=f"projects/{project_id}",
        show_deleted=False
    )

    deleted_count = 0
    try:
        for role in client.list_roles(request=request):
            # Extract role ID from full name
            role_id = role.name.split('/')[-1]

            # Check if it matches our prefix (roles use underscore)
            if role_id.startswith(f"{prefix}_"):
                if dry_run:
                    log_dry_run(f"Would delete custom role: {role_id}")
                else:
                    try:
                        delete_request = iam_admin_v1.DeleteRoleRequest(
                            name=role.name
                        )
                        client.delete_role(request=delete_request)
                        log_info(f"Deleted custom role: {role_id}")
                        deleted_count += 1
                    except gcp_exceptions.NotFound:
                        log_warn(f"Role not found (already deleted?): {role_id}")
                    except Exception as e:
                        log_error(f"Failed to delete {role_id}: {e}")
    except Exception as e:
        log_error(f"Failed to list custom roles: {e}")

    if deleted_count == 0 and not dry_run:
        print(f"No custom roles found matching prefix: {prefix}_")


def cleanup_compute_instances(project_id: str, prefix: str, dry_run: bool):
    """Delete Compute Engine instances matching the prefix."""
    print(f"\n{Colors.YELLOW}=== Cleaning up Compute Instances ==={Colors.NC}")

    client = compute_v1.InstancesClient()
    zones_client = compute_v1.ZonesClient()

    deleted_count = 0
    try:
        # Get all zones
        zones_request = compute_v1.ListZonesRequest(project=project_id)
        zones = [z.name for z in zones_client.list(request=zones_request)]

        for zone in zones:
            request = compute_v1.ListInstancesRequest(
                project=project_id,
                zone=zone
            )
            try:
                for instance in client.list(request=request):
                    if instance.name.startswith(prefix):
                        if dry_run:
                            log_dry_run(f"Would delete instance: {instance.name} in {zone}")
                        else:
                            try:
                                delete_request = compute_v1.DeleteInstanceRequest(
                                    project=project_id,
                                    zone=zone,
                                    instance=instance.name
                                )
                                operation = client.delete(request=delete_request)
                                log_info(f"Deleted instance: {instance.name}")
                                deleted_count += 1
                            except Exception as e:
                                log_error(f"Failed to delete instance {instance.name}: {e}")
            except gcp_exceptions.NotFound:
                continue

    except Exception as e:
        log_error(f"Failed to clean up compute instances: {e}")

    if deleted_count == 0 and not dry_run:
        print(f"No compute instances found matching prefix: {prefix}")


def cleanup_networks(project_id: str, prefix: str, dry_run: bool):
    """Delete VPC networks and subnets matching the prefix."""
    print(f"\n{Colors.YELLOW}=== Cleaning up VPC Networks ==={Colors.NC}")

    networks_client = compute_v1.NetworksClient()
    subnets_client = compute_v1.SubnetworksClient()
    firewalls_client = compute_v1.FirewallsClient()

    deleted_count = 0

    # First delete firewall rules
    try:
        fw_request = compute_v1.ListFirewallsRequest(project=project_id)
        for fw in firewalls_client.list(request=fw_request):
            if fw.name.startswith(prefix):
                if dry_run:
                    log_dry_run(f"Would delete firewall rule: {fw.name}")
                else:
                    try:
                        delete_request = compute_v1.DeleteFirewallRequest(
                            project=project_id,
                            firewall=fw.name
                        )
                        firewalls_client.delete(request=delete_request)
                        log_info(f"Deleted firewall rule: {fw.name}")
                    except Exception as e:
                        log_error(f"Failed to delete firewall {fw.name}: {e}")
    except Exception as e:
        log_error(f"Failed to list firewall rules: {e}")

    # Then delete networks (which will cascade to subnets)
    try:
        networks_request = compute_v1.ListNetworksRequest(project=project_id)
        for network in networks_client.list(request=networks_request):
            if network.name.startswith(prefix):
                if dry_run:
                    log_dry_run(f"Would delete network: {network.name}")
                else:
                    try:
                        delete_request = compute_v1.DeleteNetworkRequest(
                            project=project_id,
                            network=network.name
                        )
                        networks_client.delete(request=delete_request)
                        log_info(f"Deleted network: {network.name}")
                        deleted_count += 1
                    except Exception as e:
                        log_error(f"Failed to delete network {network.name}: {e}")
    except Exception as e:
        log_error(f"Failed to list networks: {e}")

    if deleted_count == 0 and not dry_run:
        print(f"No VPC networks found matching prefix: {prefix}")


def main():
    parser = argparse.ArgumentParser(
        description='Clean up GCP IAM Vulnerable resources'
    )
    parser.add_argument(
        '--project', '-p',
        required=True,
        help='GCP project ID'
    )
    parser.add_argument(
        '--prefix',
        default='privesc',
        help='Resource prefix to match (default: privesc)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be deleted without actually deleting'
    )
    parser.add_argument(
        '--force', '-f',
        action='store_true',
        help='Skip confirmation prompt'
    )

    args = parser.parse_args()

    print(f"{Colors.YELLOW}GCP IAM Vulnerable Cleanup{Colors.NC}")
    print("================================")
    print(f"Project: {args.project}")
    print(f"Prefix:  {args.prefix}")
    print(f"Dry Run: {args.dry_run}")
    print()

    if not args.force and not args.dry_run:
        response = input(f"This will DELETE resources in project {args.project}. Continue? (y/N) ")
        if response.lower() != 'y':
            print("Aborted.")
            sys.exit(0)

    # Run cleanup functions
    cleanup_service_accounts(args.project, args.prefix, args.dry_run)
    cleanup_custom_roles(args.project, args.prefix, args.dry_run)
    cleanup_compute_instances(args.project, args.prefix, args.dry_run)
    cleanup_networks(args.project, args.prefix, args.dry_run)

    print()
    if args.dry_run:
        print(f"{Colors.YELLOW}Dry run complete. No resources were modified.{Colors.NC}")
    else:
        print(f"{Colors.GREEN}Cleanup complete!{Colors.NC}")
        print()
        print("Note: Cloud Functions, Cloud Run, and Storage cleanup requires")
        print("additional libraries. Use the bash script or gcloud CLI for those.")


if __name__ == '__main__':
    main()
