# ================================================================================
# VCN
# Two-tier network: public subnet hosts phpMyAdmin; private subnet hosts
# the MySQL DB System.
#
# CIDR layout — 10.0.0.0/23:
#   10.0.0.0/25  — mysql-subnet (private, DB system)
#   10.0.1.0/25  — vm-subnet    (public,  phpMyAdmin)
# ================================================================================

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/23"
  display_name   = "mysql-vcn"
  # dns_label must be alphanumeric and ≤ 15 chars
  dns_label = "mysqlvcn"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-igw"
  enabled        = true
}

# NAT gateway provides egress-only internet access for the MySQL subnet —
# the DB system cannot be reached from the internet through it
resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-nat"
  block_traffic  = false
}

# ================================================================================
# Route Tables
# ================================================================================

# vm-subnet routes through the IGW — phpMyAdmin needs a public IP and internet
resource "oci_core_route_table" "vm" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-vm-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# mysql-subnet routes through NAT — DB system has no public endpoint
resource "oci_core_route_table" "mysql" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-db-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }
}

# ================================================================================
# Security Lists
# ================================================================================

# MySQL subnet — allow TCP 3306 only from the VM subnet CIDR
resource "oci_core_security_list" "mysql" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-sl"

  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "10.0.1.0/25"
    stateless = false

    tcp_options {
      min = 3306
      max = 3306
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# VM subnet — allow HTTP (80) and SSH (22) from internet
resource "oci_core_security_list" "vm" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "mysql-vm-sl"

  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
    stateless   = false
  }
}

# ================================================================================
# Subnets
# ================================================================================

# Private subnet — MySQL DB System lives here; no public IPs permitted
resource "oci_core_subnet" "mysql" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.0.0/25"
  display_name      = "mysql-subnet"
  dns_label         = "mysqlsub"
  route_table_id    = oci_core_route_table.mysql.id
  security_list_ids = [oci_core_security_list.mysql.id]

  prohibit_public_ip_on_vnic = true
}

# Public subnet — phpMyAdmin VM lives here with a public IP
resource "oci_core_subnet" "vm" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.1.0/25"
  display_name      = "vm-subnet"
  dns_label         = "vmsub"
  route_table_id    = oci_core_route_table.vm.id
  security_list_ids = [oci_core_security_list.vm.id]

  prohibit_public_ip_on_vnic = false
}
