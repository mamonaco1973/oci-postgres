# ================================================================================
# pgweb VM
# ================================================================================
# Ubuntu instance in the public VM subnet. Bootstrapped via cloud-init with
# pgweb pre-installed and the Pagila sample database loaded into PostgreSQL.
#
# Notes:
#   - assign_public_ip = true gives an ephemeral public IP via the IGW subnet
#   - VM_PASSWORD sets the ubuntu user's password for SSH fallback
#   - depends_on ensures PostgreSQL is ready before cloud-init attempts pagila load
# ================================================================================

resource "oci_core_instance" "pgweb" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "pgweb-vm"
  shape               = "VM.Standard.E4.Flex"

  shape_config {
    ocpus         = 1
    memory_in_gbs = 4
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.ubuntu.images[0].id
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.vm.id
    assign_public_ip = true
    display_name     = "pgweb-vnic"
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh.public_key_openssh
    user_data = base64encode(templatefile("./scripts/install_pgweb.sh.template", {
      POSTGRES_HOST     = "postgres.db.internal"
      POSTGRES_IP       = oci_psql_db_system.postgres.network_details[0].primary_db_endpoint_private_ip
      POSTGRES_PORT     = 5432
      POSTGRES_USER     = "postgres"
      POSTGRES_PASSWORD = random_password.postgres_password.result
      VM_PASSWORD       = random_password.vm_password.result
    }))
  }

  depends_on = [oci_psql_db_system.postgres]
}
