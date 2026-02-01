# GCP Compute Module - Compute Engine Instance
#
# This module creates a Compute Engine instance with a high-privilege
# service account attached, demonstrating real infrastructure privilege escalation.
#
# COST: ~$5/month for e2-micro instance
#
# EXPLOITATION SCENARIOS:
#   1. SSH via setMetadata (add SSH key to instance metadata)
#   2. SSH via OS Login
#   3. Access metadata server to get SA credentials

# Enable required APIs
resource "google_project_service" "compute" {
  project = var.project_id
  service = "compute.googleapis.com"

  disable_on_destroy = false
}

# Create a VPC network for the instance
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

# Firewall rule to allow SSH (for testing purposes)
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

# Compute Engine instance with high-priv SA attached
resource "google_compute_instance" "privesc_instance" {
  name         = "${var.resource_prefix}-instance"
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

    access_config {
      # Ephemeral public IP
    }
  }

  # Attach the high-privilege service account
  service_account {
    email  = var.high_priv_sa_email
    scopes = ["cloud-platform"]
  }

  # Enable OS Login metadata
  metadata = {
    enable-oslogin = "TRUE"
  }

  # Allow instance to be stopped for cost savings
  scheduling {
    preemptible       = true
    automatic_restart = false
  }

  depends_on = [google_project_service.compute]
}

# Output the instance details
output "instance_name" {
  description = "Name of the created instance"
  value       = google_compute_instance.privesc_instance.name
}

output "instance_zone" {
  description = "Zone of the created instance"
  value       = google_compute_instance.privesc_instance.zone
}

output "instance_external_ip" {
  description = "External IP of the instance"
  value       = google_compute_instance.privesc_instance.network_interface[0].access_config[0].nat_ip
}

output "attached_service_account" {
  description = "Service account attached to the instance"
  value       = var.high_priv_sa_email
}
