# ================================================================================
# MySQL HeatWave DB System
# ================================================================================
# Provisions a private MySQL HeatWave DB System accessible only from the VM
# subnet via private IP. No public endpoint is exposed.
#
# Notes:
#   - MySQL.2 provides 2 OCPUs and 32 GB RAM — substitute MySQL.Free for
#     always-free tier (1 OCPU / 2 GB, one per tenancy limit applies)
#   - DB System provisioning typically takes 10-20 minutes
#   - The ip_address attribute holds the private IP assigned from mysql-subnet
# ================================================================================

resource "oci_mysql_mysql_db_system" "mysql" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "mysql-db-system"
  shape_name          = "MySQL.2"
  subnet_id           = oci_core_subnet.mysql.id

  admin_username = "sysadmin"
  admin_password = random_password.mysql_password.result

  # Minimum supported storage for MySQL DB Systems
  data_storage_size_in_gb = 50

  backup_policy {
    is_enabled        = true
    retention_in_days = 7
  }
}
