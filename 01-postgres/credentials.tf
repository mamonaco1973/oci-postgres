# ================================================================================
# Passwords
# Stored as sensitive Terraform outputs in tfstate — no vault required.
# Retrieve with ./get_password.sh
# ================================================================================

resource "random_password" "postgres_password" {
  length           = 24
  special          = true
  # OCI PostgreSQL requires upper, lower, digit, and special — restrict to
  # chars that won't break double-quoted shell assignments or psql invocations
  override_special = "-@."
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "random_password" "vm_password" {
  length  = 24
  special = false
}
