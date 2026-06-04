# ================================================================================
# Outputs
# ================================================================================

output "phpmyadmin_public_ip" {
  description = "Public IP of the phpMyAdmin VM"
  value       = oci_core_instance.phpmyadmin.public_ip
}

output "mysql_ip" {
  description = "Private IP of the MySQL HeatWave DB System"
  value       = oci_mysql_mysql_db_system.mysql.ip_address
}

output "mysql_password" {
  description = "MySQL admin password — retrieve with ./get_password.sh"
  value       = random_password.mysql_password.result
  sensitive   = true
}

output "vm_password" {
  description = "phpMyAdmin VM ubuntu user password — retrieve with ./get_password.sh"
  value       = random_password.vm_password.result
  sensitive   = true
}
