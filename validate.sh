#!/bin/bash
set -euo pipefail

# ================================================================================
# Validate — wait for phpMyAdmin to become reachable, then print summary
# ================================================================================

# ------------------------------------------------------------------------------
# Resolve outputs from Terraform state
# ------------------------------------------------------------------------------

PHPMYADMIN_IP=$(terraform -chdir=01-mysql output -raw phpmyadmin_public_ip 2>/dev/null || true)
MYSQL_IP=$(terraform -chdir=01-mysql output -raw mysql_ip 2>/dev/null || true)

if [ -z "${PHPMYADMIN_IP}" ]; then
  echo "ERROR: Could not read Terraform outputs. Run ./apply.sh first."
  exit 1
fi

PHPMYADMIN_URL="http://${PHPMYADMIN_IP}"

echo "NOTE: phpMyAdmin endpoint: ${PHPMYADMIN_URL}"
echo "NOTE: MySQL private IP:    ${MYSQL_IP}"
echo "NOTE: SSH command: ssh -i 01-mysql/keys/Private_Key -o StrictHostKeyChecking=no ubuntu@${PHPMYADMIN_IP}"

# ------------------------------------------------------------------------------
# Wait for phpMyAdmin to become reachable
# cloud-init takes several minutes after instance is reported RUNNING
# ------------------------------------------------------------------------------

echo "NOTE: Waiting for phpMyAdmin to become available..."

MAX_ATTEMPTS=30
SLEEP_SECONDS=30
attempt=1

until curl -sf --head --max-time 5 "${PHPMYADMIN_URL}" > /dev/null 2>&1; do
  if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: phpMyAdmin did not become available after ${MAX_ATTEMPTS} attempts."
    exit 1
  fi
  echo "NOTE: Not reachable yet. Retry ${attempt}/${MAX_ATTEMPTS} (${SLEEP_SECONDS}s)..."
  sleep "${SLEEP_SECONDS}"
  attempt=$((attempt + 1))
done

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------

echo ""
echo "================================================================================"
echo "BUILD VALIDATION RESULTS"
echo "================================================================================"
echo "phpMyAdmin URL  : ${PHPMYADMIN_URL}"
echo "MySQL Private IP: ${MYSQL_IP}"
echo "Credentials     : ./get_password.sh"
echo "================================================================================"
