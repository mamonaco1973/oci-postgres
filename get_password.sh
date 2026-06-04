#!/bin/bash
set -euo pipefail

# ================================================================================
# get_password.sh — print credentials from Terraform state
# ================================================================================

MYSQL_PASSWORD=$(terraform -chdir=01-mysql output -raw mysql_password 2>/dev/null)
VM_PASSWORD=$(terraform -chdir=01-mysql output -raw vm_password 2>/dev/null)
PHPMYADMIN_IP=$(terraform -chdir=01-mysql output -raw phpmyadmin_public_ip 2>/dev/null)
MYSQL_IP=$(terraform -chdir=01-mysql output -raw mysql_ip 2>/dev/null)

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "ERROR: Could not read outputs from tfstate — has 01-mysql been applied?"
  exit 1
fi

echo "MySQL (HeatWave DB System):"
echo "  Username : sysadmin"
echo "  Password : ${MYSQL_PASSWORD}"
echo "  Host     : ${MYSQL_IP} (private)"
echo ""
echo "phpMyAdmin VM:"
echo "  Username : ubuntu"
echo "  Password : ${VM_PASSWORD}"
echo "  Public IP: ${PHPMYADMIN_IP}"
echo "  URL      : http://${PHPMYADMIN_IP}"
