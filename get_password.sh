#!/bin/bash
set -euo pipefail

# ================================================================================
# get_password.sh — print credentials from Terraform state
# ================================================================================

POSTGRES_PASSWORD=$(terraform -chdir=01-postgres output -raw postgres_password 2>/dev/null)
VM_PASSWORD=$(terraform -chdir=01-postgres output -raw vm_password 2>/dev/null)
PGWEB_IP=$(terraform -chdir=01-postgres output -raw pgweb_public_ip 2>/dev/null)
POSTGRES_PRIVATE_IP=$(terraform -chdir=01-postgres output -raw postgres_private_ip 2>/dev/null)

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "ERROR: Could not read outputs from tfstate — has 01-postgres been applied?"
  exit 1
fi

echo "PostgreSQL DB System:"
echo "  Username : postgres"
echo "  Password : ${POSTGRES_PASSWORD}"
echo "  Host     : ${POSTGRES_PRIVATE_IP} (private)"
echo ""
echo "pgweb VM:"
echo "  Username : ubuntu"
echo "  Password : ${VM_PASSWORD}"
echo "  Public IP: ${PGWEB_IP}"
echo "  URL      : http://${PGWEB_IP}"
