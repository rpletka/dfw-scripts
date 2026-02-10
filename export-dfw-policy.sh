#!/usr/bin/env bash
set -euo pipefail

########################################
# Verify env vars only (not functions)
########################################
if [[ -z "${NSX_MGR:-}" || -z "${NSX_USER:-}" || -z "${NSX_PASS:-}" ]]; then
  echo "❌ NSX environment not loaded."
  echo "Run:"
  echo "  source set-nsx-env.sh"
  exit 1
fi

########################################
DEFAULT_PATH="/infra/domains/default/security-policies/default-layer3-section"

echo "=== Export NSX Policy ==="

read -r -p "Policy path [$DEFAULT_PATH]: " POLICY_PATH
POLICY_PATH=${POLICY_PATH:-$DEFAULT_PATH}

DEFAULT_FILE="$(basename "$POLICY_PATH").json"

read -r -p "Output filename [$DEFAULT_FILE]: " OUTFILE
OUTFILE=${OUTFILE:-$DEFAULT_FILE}

URL="https://$NSX_MGR/policy/api/v1$POLICY_PATH"

echo
echo "⬇️  Exporting:"
echo "   $URL"
echo

curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -H "Accept: application/json" \
  "$URL" | jq '.' > "$OUTFILE"

echo "✅ Export complete → $OUTFILE"

