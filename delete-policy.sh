#!/usr/bin/env bash
set -euo pipefail

########################################
# Verify environment
########################################
if [[ -z "${NSX_MGR:-}" || -z "${NSX_USER:-}" || -z "${NSX_PASS:-}" ]]; then
  echo "❌ NSX environment not loaded."
  echo "Run:"
  echo "  source set-nsx-env.sh"
  exit 1
fi

echo "=== Delete NSX Security Policy ==="

########################################
# Input: ID or full path
########################################
INPUT="${1:-}"

if [[ -z "$INPUT" ]]; then
  read -r -p "Policy ID or full path to delete: " INPUT
fi

########################################
# Normalize to full path
########################################
if [[ "$INPUT" == /infra/* ]]; then
  POLICY_PATH="$INPUT"
else
  POLICY_PATH="/infra/domains/default/security-policies/$INPUT"
fi

POLICY_URL="https://$NSX_MGR/policy/api/v1$POLICY_PATH"

echo
echo "⚠️  You are about to DELETE:"
echo "   $POLICY_PATH"
echo

read -r -p "Type DELETE to confirm: " CONFIRM

if [[ "$CONFIRM" != "DELETE" ]]; then
  echo "❌ Aborted"
  exit 1
fi

########################################
# Delete
########################################
curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -X DELETE \
  "$POLICY_URL"

echo "✅ Policy deleted successfully"

