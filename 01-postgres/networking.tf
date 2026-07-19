# ================================================================================
# VCN
# Two-tier network: public subnet hosts pgweb; private subnet hosts
# the PostgreSQL DB System.
#
# CIDR layout — 10.0.0.0/23:
#   10.0.0.0/25  — private-subnet  (private, DB system)
#   10.0.1.0/25  — public-subnet   (public,  pgweb VM)
# ================================================================================

resource "oci_core_vcn" "main" {
  compartment_id = var.compartment_ocid
  cidr_block     = "10.0.0.0/23"
  display_name   = "postgres-vcn"
  dns_label      = "postgresvcn"
}

resource "oci_core_internet_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "postgres-igw"
  enabled        = true
}

# NAT gateway provides egress-only internet access for the PostgreSQL subnet
resource "oci_core_nat_gateway" "main" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "postgres-nat"
  block_traffic  = false
}

# ================================================================================
# Route Tables
# ================================================================================

# public-subnet routes through the IGW — pgweb needs a public IP and internet
resource "oci_core_route_table" "vm" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "postgres-vm-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
}

# private-subnet routes through NAT — DB system has no public endpoint
resource "oci_core_route_table" "postgres" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "postgres-db-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.main.id
  }
}

# ================================================================================
# Security Lists
# ================================================================================

# PostgreSQL subnet — allow TCP 5432 only from the VM subnet CIDR
resource "oci_core_security_list" "postgres" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "postgres-sl"

  ingress_security_rules {
    protocol  = "6" # TCP
    source    = "10.0.1.0/25"
    stateless = false

    tcp_options {
      min = 5432
      max = 5432
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
  display_name   = "postgres-vm-sl"

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

# Private subnet — PostgreSQL DB System lives here; no public IPs permitted
resource "oci_core_subnet" "postgres" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.0.0/25"
  display_name      = "private-subnet"
  dns_label         = "postgressub"
  route_table_id    = oci_core_route_table.postgres.id
  security_list_ids = [oci_core_security_list.postgres.id]

  prohibit_public_ip_on_vnic = true
}

# Public subnet — pgweb VM lives here with a public IP
resource "oci_core_subnet" "vm" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.main.id
  cidr_block        = "10.0.1.0/25"
  display_name      = "public-subnet"
  dns_label         = "vmsub"
  route_table_id    = oci_core_route_table.vm.id
  security_list_ids = [oci_core_security_list.vm.id]

  prohibit_public_ip_on_vnic = false
}
