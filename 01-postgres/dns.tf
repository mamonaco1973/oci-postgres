# OCI managed PostgreSQL does not support hostname_label on network_details.
# The friendly FQDN (postgres.db.internal) is written to /etc/hosts on the
# pgweb VM during cloud-init. pgweb resolves hostnames server-side so this
# is sufficient without any DNS zone infrastructure.
