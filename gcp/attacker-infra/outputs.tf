output "attacker_instance_ip" {
  description = "External IP address of the attacker instance"
  value       = var.enable_attacker_instance ? google_compute_instance.attacker[0].network_interface[0].access_config[0].nat_ip : null
}

output "attacker_instance_name" {
  description = "Name of the attacker instance"
  value       = var.enable_attacker_instance ? google_compute_instance.attacker[0].name : null
}

output "attacker_instance_dns" {
  description = "DNS name of the attacker instance (sslip.io or custom dns_name)"
  value       = var.enable_attacker_instance ? (var.dns_name != "" ? var.dns_name : "${replace(google_compute_instance.attacker[0].network_interface[0].access_config[0].nat_ip, ".", "-")}.sslip.io") : null
}

output "attacker_bucket_name" {
  description = "Name of the attacker staging bucket (free unless objects are stored)"
  value       = google_storage_bucket.attacker.name
}

output "ssh_private_key_path" {
  description = "Path to the SSH private key file"
  value       = local_file.ssh_private_key.filename
}

output "ssh_command" {
  description = "Ready-to-use SSH command to connect to the attacker instance"
  value       = var.enable_attacker_instance ? "ssh -i ${local_file.ssh_private_key.filename} ${local.ssh_username}@${google_compute_instance.attacker[0].network_interface[0].access_config[0].nat_ip}" : null
}

output "cert_fullchain_path" {
  description = "Path to the TLS certificate fullchain on the attacker instance"
  value       = var.enable_certbot && var.enable_attacker_instance ? "/home/${local.ssh_username}/certs/fullchain.pem" : null
}

output "cert_privkey_path" {
  description = "Path to the TLS certificate private key on the attacker instance"
  value       = var.enable_certbot && var.enable_attacker_instance ? "/home/${local.ssh_username}/certs/privkey.pem" : null
}
