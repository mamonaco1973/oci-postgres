# ================================================================================
# Outputs
# ================================================================================

output "pgweb_public_ip" {
  description = "Public IP of the pgweb VM"
  value       = oci_core_instance.pgweb.public_ip
}

output "postgres_endpoint" {
  description = "Private FQDN of the PostgreSQL DB System"
  value       = oci_psql_db_system.postgres.network_endpoint_details[0].primary_db_endpoint_fqdn
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
