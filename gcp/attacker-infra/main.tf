terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

# Get the deployer's email for SSH username
data "google_client_openid_userinfo" "me" {}

# Get the deployer's external IP for SSH firewall rule
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Random suffix for globally-unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------

locals {
  ssh_username   = split("@", data.google_client_openid_userinfo.me.email)[0]
  deployer_email = data.google_client_openid_userinfo.me.email
  deployer_ip    = trimspace(data.http.my_ip.response_body)
}

# ---------------------------------------------------------------------------
# APIs
# ---------------------------------------------------------------------------

resource "google_project_service" "compute" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage" {
  project            = var.gcp_project_id
  service            = "storage.googleapis.com"
  disable_on_destroy = false
}

# ---------------------------------------------------------------------------
# Networking (always created - free)
# ---------------------------------------------------------------------------

resource "google_compute_network" "attacker" {
  name                    = "attacker-network"
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute]
}

resource "google_compute_subnetwork" "attacker" {
  name          = "attacker-subnet"
  ip_cidr_range = "10.1.0.0/24"
  region        = var.gcp_region
  network       = google_compute_network.attacker.id
}

# SSH - restricted to deployer's IP only
resource "google_compute_firewall" "attacker_ssh" {
  name    = "attacker-allow-ssh"
  network = google_compute_network.attacker.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["${local.deployer_ip}/32"]
  target_tags   = ["attacker-instance"]
}

# Web ports - open to all (needed for callbacks, reverse shells, C2 listeners)
resource "google_compute_firewall" "attacker_web" {
  name    = "attacker-allow-web"
  network = google_compute_network.attacker.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080", "8443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["attacker-instance"]
}

# ---------------------------------------------------------------------------
# SSH Key (always created - free, persists across instance rebuilds)
# ---------------------------------------------------------------------------

resource "tls_private_key" "attacker" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.attacker.private_key_pem
  filename        = "${path.module}/attacker-ssh-key.pem"
  file_permission = "0600"
}

# ---------------------------------------------------------------------------
# Storage Bucket (always created - free unless objects are stored)
# ---------------------------------------------------------------------------

resource "google_storage_bucket" "attacker" {
  name                        = "${var.gcp_project_id}-attacker-bucket-${random_id.bucket_suffix.hex}"
  location                    = "US"
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [google_project_service.storage]
}

# ---------------------------------------------------------------------------
# Compute Instance (gated by enable_attacker_instance - only resource that costs money)
# ---------------------------------------------------------------------------

resource "google_compute_instance" "attacker" {
  count        = var.enable_attacker_instance ? 1 : 0
  name         = "attacker-instance"
  machine_type = "e2-micro"
  zone         = var.gcp_zone

  tags = ["attacker-instance"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12-bookworm-v20250113"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.attacker.id

    # Public IP
    access_config {}
  }

  # Spot/preemptible for cost savings
  scheduling {
    preemptible                 = true
    provisioning_model          = "SPOT"
    automatic_restart           = false
    instance_termination_action = "STOP"
  }

  metadata = {
    ssh-keys       = "${local.ssh_username}:${tls_private_key.attacker.public_key_openssh}"
    startup-script = var.enable_certbot ? templatefile("${path.module}/startup.sh.tftpl", {
      certbot_email = local.deployer_email
      ssh_username  = local.ssh_username
      dns_name      = var.dns_name
    }) : null
  }

  # No service account - this is attacker infra, not a privesc target
  service_account {
    scopes = []
  }

  deletion_protection = false
}
