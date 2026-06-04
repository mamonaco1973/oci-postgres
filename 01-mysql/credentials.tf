# ================================================================================
# Passwords
# Stored as sensitive Terraform outputs in tfstate — no vault required.
# Retrieve with ./get_password.sh
# ================================================================================

resource "random_password" "mysql_password" {
  length           = 24
  special          = true
  # OCI MySQL requires upper, lower, digit, and special — restrict to
  # chars that won't break double-quoted shell assignments or -p"..." args
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
