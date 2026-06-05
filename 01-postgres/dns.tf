# ================================================================================
# Private DNS
# Creates a private DNS zone scoped to this VCN so the PostgreSQL endpoint
# can be reached by a stable FQDN instead of a raw private IP.
#
# Zone:  postgres-<hex>.internal
# FQDN:  db.postgres-<hex>.internal  →  PostgreSQL primary private IP
# ================================================================================

resource "random_id" "dns" {
  byte_length = 4
}

# Look up the DNS resolver OCI auto-created for the VCN
data "oci_core_vcn_dns_resolver_association" "main" {
  vcn_id = oci_core_vcn.main.id
}

# Private view — container for our custom DNS zone
resource "oci_dns_view" "private" {
  compartment_id = var.compartment_ocid
  scope          = "PRIVATE"
  display_name   = "postgres-dns-view"
}

# Private zone hosted in the custom view
resource "oci_dns_zone" "private" {
  compartment_id = var.compartment_ocid
  name           = "postgres-${random_id.dns.hex}.internal"
  zone_type      = "PRIMARY"
  scope          = "PRIVATE"
  view_id        = oci_dns_view.private.id
}

# A record: db.<zone> → PostgreSQL primary private IP
resource "oci_dns_rrset" "postgres" {
  zone_name_or_id = oci_dns_zone.private.id
  domain          = "db.postgres-${random_id.dns.hex}.internal"
  rtype           = "A"
  scope           = "PRIVATE"
  view_id         = oci_dns_view.private.id

  items {
    domain = "db.postgres-${random_id.dns.hex}.internal"
    rtype  = "A"
    ttl    = 300
    rdata  = oci_psql_db_system.postgres.network_details[0].primary_db_endpoint_private_ip
  }
}

# Attach the custom view to the VCN's managed resolver so instances can resolve it
resource "oci_dns_resolver" "vcn" {
  resolver_id = data.oci_core_vcn_dns_resolver_association.main.dns_resolver_id
  scope       = "PRIVATE"

  attached_views {
    view_id = oci_dns_view.private.id
  }

  depends_on = [oci_dns_zone.private]
}
