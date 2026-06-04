# ================================================================================
# phpMyAdmin VM
# ================================================================================
# Ubuntu instance in the public VM subnet. Bootstrapped via cloud-init with
# phpMyAdmin pre-configured to connect to the MySQL DB System private IP.
#
# Notes:
#   - assign_public_ip = true gives an ephemeral public IP from the IGW subnet
#   - VM_PASSWORD sets the ubuntu user's password for console/SSH fallback
#   - depends_on ensures MySQL is ready before cloud-init attempts sakila import
# ================================================================================

resource "oci_core_instance" "phpmyadmin" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "phpmyadmin-vm"
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
    display_name     = "phpmyadmin-vnic"
  }

  metadata = {
    ssh_authorized_keys = tls_private_key.ssh.public_key_openssh
    user_data = base64encode(templatefile("./scripts/phpmyadmin.sh.template", {
      PASSWORD    = random_password.mysql_password.result
      MYSQL_HOST  = oci_mysql_mysql_db_system.mysql.ip_address
      USER        = "sysadmin"
      VM_PASSWORD = random_password.vm_password.result
    }))
  }

  depends_on = [oci_mysql_mysql_db_system.mysql]
}
