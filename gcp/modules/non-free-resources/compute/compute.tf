# GCP Compute Module - Compute Engine Instances
#
# This module creates Compute Engine instances for compute-based privesc paths.
# Each path gets its own dedicated instance with appropriate naming.
#
# COST: ~$6-7/month per e2-micro instance (standard)

# =============================================================================
# SSH Key Generation for Privesc13 (existingSSH)
# =============================================================================

# Generate SSH key pair for lateral7 (existingSSH)
resource "tls_private_key" "lateral7_ssh" {
  count = var.enable_lateral7 ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file for exploitation
resource "local_file" "lateral7_private_key" {
  count = var.enable_lateral7 ? 1 : 0

  content         = tls_private_key.lateral7_ssh[0].private_key_pem
  filename        = "${path.root}/lateral7-sshkey.pem"
  file_permission = "0600"
}

# =============================================================================
# SSH Key Generation for Privesc13 (OS Login)
# =============================================================================

# Generate SSH key pair for privesc13
resource "tls_private_key" "privesc13_ssh" {
  count = var.enable_privesc13 ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key to local file for exploitation
resource "local_file" "privesc13_private_key" {
  count = var.enable_privesc13 ? 1 : 0

  content         = tls_private_key.privesc13_ssh[0].private_key_pem
  filename        = "${path.root}/privesc13-sshkey.pem"
  file_permission = "0600"
}

# Save public key to local file (needed for os-login ssh-keys add)
# Named .pem.pub so gcloud can find it when using --ssh-key-file=privesc13-sshkey.pem
resource "local_file" "privesc13_public_key" {
  count = var.enable_privesc13 ? 1 : 0

  content         = tls_private_key.privesc13_ssh[0].public_key_openssh
  filename        = "${path.root}/privesc13-sshkey.pem.pub"
  file_permission = "0644"
}

# =============================================================================
# Networking
# =============================================================================

# Enable required APIs
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Create a VPC network for the instances
resource "google_compute_network" "privesc_network" {
  name                    = "${var.resource_prefix}-network"
  project                 = var.project_id
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

# Create a subnet
resource "google_compute_subnetwork" "privesc_subnet" {
  name          = "${var.resource_prefix}-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.privesc_network.id
  ip_cidr_range = "10.0.0.0/24"
}

# Firewall rule to allow SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.resource_prefix}-allow-ssh"
  project = var.project_id
  network = google_compute_network.privesc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["privesc-instance"]
}

# =============================================================================
# Per-Path Instances
# =============================================================================

# Privesc11: setMetadata (manual key injection)
resource "google_compute_instance" "privesc11_instance" {
  count = var.enable_privesc11 ? 1 : 0

  name         = "${var.resource_prefix}11-instance"
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["privesc-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privesc_subnet.id
    access_config {}
  }

  service_account {
    email  = var.high_priv_sa_email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart = true
  }

  deletion_protection = false
  depends_on          = [google_project_service.compute]
}

# Privesc12: setCommonInstanceMetadata (project-level)
resource "google_compute_instance" "privesc12_instance" {
  count = var.enable_privesc12 ? 1 : 0

  name         = "${var.resource_prefix}12-instance"
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["privesc-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privesc_subnet.id
    access_config {}
  }

  service_account {
    email  = var.high_priv_sa_email
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart = true
  }

  deletion_protection = false
  depends_on          = [google_project_service.compute]
}

# Lateral7: existingSSH
resource "google_compute_instance" "lateral7_instance" {
  count = var.enable_lateral7 ? 1 : 0

  name         = "${var.resource_prefix}-lateral7-instance"
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["privesc-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privesc_subnet.id
    access_config {}
  }

  service_account {
    email  = var.high_priv_sa_email
    scopes = ["cloud-platform"]
  }

  # The attacker's SSH key is already in metadata
  # This simulates an admin having added the attacker's key previously
  # The private key is saved to lateral7-sshkey.pem in the project root
  metadata = {
    ssh-keys = "lateral7:${tls_private_key.lateral7_ssh[0].public_key_openssh}"
  }

  scheduling {
    automatic_restart = true
  }

  deletion_protection = false
  depends_on          = [google_project_service.compute, tls_private_key.lateral7_ssh]
}

# Privesc13: osLogin
resource "google_compute_instance" "privesc13_instance" {
  count = var.enable_privesc13 ? 1 : 0

  name         = "${var.resource_prefix}13-instance"
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["privesc-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privesc_subnet.id
    access_config {}
  }

  service_account {
    email  = var.high_priv_sa_email
    scopes = ["cloud-platform"]
  }

  # Enable OS Login for this instance
  metadata = {
    enable-oslogin = "TRUE"
  }

  scheduling {
    automatic_restart = true
  }

  deletion_protection = false
  depends_on          = [google_project_service.compute]
}

# Privesc14: setServiceAccount
resource "google_compute_instance" "privesc14_instance" {
  count = var.enable_privesc14 ? 1 : 0

  name         = "${var.resource_prefix}14-instance"
  project      = var.project_id
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["privesc-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 10
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.privesc_subnet.id
    access_config {}
  }

  # This instance starts with default compute SA, attacker will change it to high-priv
  service_account {
    email  = "${var.project_id}@appspot.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  scheduling {
    automatic_restart = true
  }

  # Allow Terraform to stop the instance to reset the SA after exploitation
  allow_stopping_for_update = true

  deletion_protection = false
  depends_on          = [google_project_service.compute]
}

# =============================================================================
# Outputs
# =============================================================================

output "privesc11_instance_name" {
  description = "Name of privesc11 instance"
  value       = var.enable_privesc11 ? google_compute_instance.privesc11_instance[0].name : null
}

output "privesc12_instance_name" {
  description = "Name of privesc12 instance"
  value       = var.enable_privesc12 ? google_compute_instance.privesc12_instance[0].name : null
}

output "lateral7_instance_name" {
  description = "Name of lateral7 instance"
  value       = var.enable_lateral7 ? google_compute_instance.lateral7_instance[0].name : null
}

output "privesc13_instance_name" {
  description = "Name of privesc13 instance"
  value       = var.enable_privesc13 ? google_compute_instance.privesc13_instance[0].name : null
}

output "privesc14_instance_name" {
  description = "Name of privesc14 instance"
  value       = var.enable_privesc14 ? google_compute_instance.privesc14_instance[0].name : null
}

output "instance_zone" {
  description = "Zone of the instances"
  value       = var.zone
}

output "attached_service_account" {
  description = "High-privilege service account attached to instances"
  value       = var.high_priv_sa_email
}

output "lateral7_instance_external_ip" {
  description = "External IP of lateral7 instance"
  value       = var.enable_lateral7 ? google_compute_instance.lateral7_instance[0].network_interface[0].access_config[0].nat_ip : null
}

output "lateral7_ssh_private_key_path" {
  description = "Path to the lateral7 SSH private key"
  value       = var.enable_lateral7 ? "${path.root}/lateral7-sshkey.pem" : null
}

output "privesc13_instance_external_ip" {
  description = "External IP of privesc13 instance (OS Login)"
  value       = var.enable_privesc13 ? google_compute_instance.privesc13_instance[0].network_interface[0].access_config[0].nat_ip : null
}

output "privesc13_ssh_private_key_path" {
  description = "Path to the privesc13 SSH private key"
  value       = var.enable_privesc13 ? "${path.root}/privesc13-sshkey.pem" : null
}

output "privesc13_ssh_public_key_path" {
  description = "Path to the privesc13 SSH public key (for os-login ssh-keys add)"
  value       = var.enable_privesc13 ? "${path.root}/privesc13-sshkey.pem.pub" : null
}
