#!/bin/bash
set -euo pipefail

# ================================================================================
# Destroy — tear down the PostgreSQL Terraform stack and all OCI resources
# ================================================================================

# Resolve compartment — fall back to tenancy OCID if OCI_COMPARTMENT_ID is unset
if [ -z "${OCI_COMPARTMENT_ID:-}" ]; then
  OCI_COMPARTMENT_ID=$(awk -F'=' '/^tenancy[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ~/.oci/config)
fi
export TF_VAR_compartment_ocid="$OCI_COMPARTMENT_ID"

terraform -chdir=01-postgres init
terraform -chdir=01-postgres destroy -auto-approve
