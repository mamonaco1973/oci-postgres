# ================================================================================
# Outputs
# ================================================================================

output "pgweb_public_ip" {
  description = "Public IP of the pgweb VM"
  value       = oci_core_instance.pgweb.public_ip
}

output "postgres_private_ip" {
  description = "Private IP of the PostgreSQL DB System primary endpoint"
  value       = oci_psql_db_system.postgres.network_details[0].primary_db_endpoint_private_ip
}

output "postgres_fqdn" {
  description = "Private DNS FQDN for the PostgreSQL endpoint (resolvable within the VCN)"
  value       = "db.postgres-${random_id.dns.hex}.internal"
}

output "postgres_password" {
  description = "PostgreSQL admin password — retrieve with ./get_password.sh"
  value       = random_password.postgres_password.result
  sensitive   = true
}

output "vm_password" {
  description = "pgweb VM ubuntu user password — retrieve with ./get_password.sh"
  value       = random_password.vm_password.result
  sensitive   = true
}
