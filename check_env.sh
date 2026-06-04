#!/bin/bash
set -euo pipefail

# ================================================================================
# Environment Check
# Validates required tools are installed and OCI credentials are active
# ================================================================================

# ------------------------------------------------------------------------------
# Tool Checks
# ------------------------------------------------------------------------------

echo "NOTE: Validating that required commands are found in your PATH."

for cmd in oci terraform jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: $cmd is not found in PATH."
    exit 1
  fi
  echo "NOTE: $cmd is found in the current PATH."
done

echo "NOTE: All required commands are available."

# ------------------------------------------------------------------------------
# OCI Credentials
# oci iam region list is the cheapest call to confirm credentials are active
# ------------------------------------------------------------------------------

echo "NOTE: Checking OCI CLI connection."

if ! oci iam region list &>/dev/null; then
  echo "ERROR: OCI credentials are not configured or have expired."
  exit 1
fi

echo "NOTE: Successfully connected to OCI."

# ------------------------------------------------------------------------------
# OCI Compartment Check
# ------------------------------------------------------------------------------
echo "NOTE: Checking OCI_COMPARTMENT_ID environment variable."
if [ -z "${OCI_COMPARTMENT_ID:-}" ]; then
  tenancy=$(awk -F'=' '/^tenancy[[:space:]]*=/{gsub(/[[:space:]]/, "", $2); print $2; exit}' ~/.oci/config)
  if [ -z "$tenancy" ]; then
    echo "ERROR: OCI_COMPARTMENT_ID is not set and tenancy could not be read from ~/.oci/config."
    exit 1
  fi
  echo "WARNING: OCI_COMPARTMENT_ID not set — will use tenancy OCID from ~/.oci/config."
else
  echo "NOTE: OCI_COMPARTMENT_ID is set."
fi
