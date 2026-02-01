# IAM Vulnerable

Use Terraform to create your own *vulnerable by design* cloud IAM privilege escalation playground.

![](.images/IAMVulnerable-350px.png)

IAM Vulnerable uses Terraform and your cloud credentials to deploy intentionally vulnerable IAM configurations. Within minutes, you can start learning how to identify and exploit vulnerable IAM configurations that allow for privilege escalation.

## Supported Cloud Platforms

| Cloud | Directory | Privilege Escalation Paths | Cost |
|-------|-----------|---------------------------|------|
| **AWS** | [`aws/`](aws/) | 31 paths | Free (IAM only) |
| **GCP** | [`gcp/`](gcp/) | 43 paths | Free (IAM only) |

## Quick Start

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

See platform-specific documentation for detailed setup:
- **AWS**: [aws/README.md](aws/README.md)
- **GCP**: [gcp/README.md](gcp/README.md)

## CloudFoxable - IAM Vulnerable's Big Brother

IAM Vulnerable is useful for understanding the basic building blocks of cloud IAM privilege escalation. For a more comprehensive, CTF-style experience that teaches cloud penetration testing holistically, check out:

- [CloudFoxable - A Gamified Cloud Hacking Sandbox](https://cloudfoxable.bishopfox.com/)
- Join us on the [RedSec Discord server](https://discord.gg/redsec)

## Cost Summary

Both platforms deploy **free** IAM-only resources by default. Optional modules with compute resources can be enabled for hands-on testing:

| Platform | Default Cost | Optional Modules |
|----------|--------------|------------------|
| **AWS** | $0 | EC2 (~$4.50/mo), Lambda (free tier), Glue (~$4/hr), SageMaker (varies) |
| **GCP** | $0 | Compute (~$2-3/mo), Cloud Functions (free tier), Cloud Run (free tier) |

## Testing Tools

**AWS:**
- [Principal Mapper (PMapper)](https://github.com/nccgroup/PMapper)
- [Pacu](https://github.com/RhinoSecurityLabs/pacu)
- [Cloudsplaining](https://github.com/salesforce/cloudsplaining/)
- [AWSPX](https://github.com/FSecureLABS/awspx)
- [FoxMapper](https://github.com/BishopFox/foxmapper)

**GCP:**
- [FoxMapper](https://github.com/BishopFox/foxmapper)
- [gcpwn](https://github.com/NetSPI/gcpwn)

## Cleanup

```bash
# AWS
cd aws && terraform destroy

# GCP
cd gcp && terraform destroy
```

If Terraform state is lost, see the cleanup scripts in each platform's `cleanup-scripts/` directory.

## FAQ

**How does IAM Vulnerable compare to CloudGoat, Terragoat, and SadCloud?**

All use Terraform to deploy intentionally vulnerable infrastructure. IAM Vulnerable's focus is specifically **IAM privilege escalation**, whereas other tools cover broader vulnerability categories but may not comprehensively cover IAM privesc scenarios.

**Can I run AWS and GCP simultaneously?**

Yes! Each platform has separate Terraform state in its own directory.

## References

- [Privilege Escalation in AWS - Rhino Security Labs](https://rhinosecuritylabs.com/aws/aws-privilege-escalation-methods-mitigation/)
- [Privilege Escalation in GCP - GitLab](https://about.gitlab.com/blog/2020/02/12/plundering-gcp-escalating-privileges-in-google-cloud-platform/)
- [AWS IAM Roles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles.html)
- [GCP IAM Roles](https://cloud.google.com/iam/docs/understanding-roles)
