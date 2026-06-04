#!/bin/bash
set -euo pipefail

# ================================================================================
# Validate — wait for pgweb to become reachable, then print summary
# ================================================================================

# ------------------------------------------------------------------------------
# Resolve outputs from Terraform state
# ------------------------------------------------------------------------------

PGWEB_IP=$(terraform -chdir=01-postgres output -raw pgweb_public_ip 2>/dev/null || true)
POSTGRES_ENDPOINT=$(terraform -chdir=01-postgres output -raw postgres_endpoint 2>/dev/null || true)

if [ -z "${PGWEB_IP}" ]; then
  echo "ERROR: Could not read Terraform outputs. Run ./apply.sh first."
  exit 1
fi

PGWEB_URL="http://${PGWEB_IP}"

echo "NOTE: SSH command: ssh -i 01-postgres/keys/Private_Key -o StrictHostKeyChecking=no ubuntu@${PGWEB_IP}"
echo "NOTE: pgweb endpoint:        ${PGWEB_URL}"
echo "NOTE: PostgreSQL private DNS: ${POSTGRES_ENDPOINT}"

# ------------------------------------------------------------------------------
# Wait for pgweb to become reachable
# cloud-init takes several minutes after instance is reported RUNNING
# ------------------------------------------------------------------------------

echo "NOTE: Waiting for pgweb to become available..."

MAX_ATTEMPTS=30
SLEEP_SECONDS=30
attempt=1

until curl -sf --head --max-time 5 "${PGWEB_URL}" > /dev/null 2>&1; do
  if [ "${attempt}" -ge "${MAX_ATTEMPTS}" ]; then
    echo "ERROR: pgweb did not become available after ${MAX_ATTEMPTS} attempts."
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
echo "pgweb URL            : ${PGWEB_URL}"
echo "PostgreSQL private DNS: ${POSTGRES_ENDPOINT}"
echo "Credentials          : ./get_password.sh"
echo "================================================================================"
