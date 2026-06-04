# ================================================================================
# OCI PostgreSQL DB System
# ================================================================================
# Provisions a private PostgreSQL DB System accessible only from the VM subnet
# via private FQDN. No public endpoint is exposed.
#
# Notes:
#   - PostgreSQL.VM.Standard.E4.Flex.2.32GB — 2 OCPUs, 32 GB RAM
#   - instance_count = 1 — single node (no HA standby)
#   - DB System provisioning typically takes 10-20 minutes
#   - Endpoint FQDN is available via network_endpoint_details after creation
# ================================================================================

resource "oci_psql_db_system" "postgres" {
  compartment_id = var.compartment_ocid
  display_name   = "postgres-db-system"
  db_version     = "14"
  shape          = "PostgreSQL.VM.Standard.E5.Flex.2.32GB"
  instance_count = 1

  credentials {
    username = "postgres"
    password_details {
      password_type = "PLAIN_TEXT"
      password      = random_password.postgres_password.result
    }
  }

  network_details {
    subnet_id = oci_core_subnet.postgres.id
  }

  storage_details {
    # OCI_OPTIMIZED_STORAGE is the standard block storage backend
    system_type           = "OCI_OPTIMIZED_STORAGE"
    is_regionally_durable = false
    availability_domain   = data.oci_identity_availability_domains.ads.availability_domains[0].name
  }
}
