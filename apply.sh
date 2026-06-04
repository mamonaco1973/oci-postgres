#!/bin/bash
set -euo pipefail

# ================================================================================
# Apply — validate env, deploy PostgreSQL stack, run post-deployment validation
# ================================================================================

./check_env.sh
if [ $? -ne 0 ]; then
  echo "ERROR: Environment check failed. Exiting."
  exit 1
fi

# Resolve compartment — fall back to tenancy OCID if OCI_COMPARTMENT_ID is unset
if [ -z "${OCI_COMPARTMENT_ID:-}" ]; then
  OCI_COMPARTMENT_ID=$(awk -F'=' '/^tenancy[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ~/.oci/config)
fi
export TF_VAR_compartment_ocid="$OCI_COMPARTMENT_ID"

terraform -chdir=01-postgres init
terraform -chdir=01-postgres apply -auto-approve

./validate.sh
