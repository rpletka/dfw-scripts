#!/usr/bin/env bash
set -euo pipefail

########################################
# Validate environment
########################################
if [[ -z "${NSX_MGR:-}" || -z "${NSX_USER:-}" || -z "${NSX_PASS:-}" ]]; then
  echo "❌ NSX environment not loaded."
  echo "Run: source set-nsx-env.sh"
  exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 vm-tags-summary.json"
  exit 1
fi

FILE="$1"

command -v jq >/dev/null 2>&1 || {
  echo "❌ jq required"
  exit 1
}

echo "📦 Restoring VM tags from $FILE"
echo

########################################
# Fetch current VM inventory
########################################
echo "🔎 Fetching VM inventory..."

VM_DATA=$(curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/api/v1/fabric/virtual-machines")

########################################
# Helper: get VM external_id by name
########################################
get_vm_id() {
  local name="$1"

  echo "$VM_DATA" | jq -r --arg n "$name" '
    (.results // [])
    | map(select(.display_name==$n))
    | .[0].external_id // empty
  '
}

########################################
# Process each VM
########################################
jq -c '.[]' "$FILE" | while IFS= read -r entry; do

  NAME=$(echo "$entry" | jq -r '.name')
  TAGS=$(echo "$entry" | jq '.tags')

  VM_ID=$(get_vm_id "$NAME")

  if [[ -z "$VM_ID" ]]; then
    echo "⚠️  VM not found → $NAME"
    continue
  fi

  ########################################
  # Get current tags
  ########################################
  CURRENT_TAGS=$(echo "$VM_DATA" | jq --arg id "$VM_ID" '
    (.results // [])
    | map(select(.external_id==$id))
    | .[0].tags // []
  ')

  ########################################
  # Merge + dedupe tags
  ########################################
  MERGED_TAGS=$(jq -n \
    --argjson a "$CURRENT_TAGS" \
    --argjson b "$TAGS" \
    '
    ($a + $b)
    | unique_by(.scope + ":" + .tag)
    ')

  ########################################
  # Apply tags
  ########################################
  echo "🏷️  Applying tags → $NAME"

  curl -sS -k -u "$NSX_USER:$NSX_PASS" \
    -X PATCH \
    "https://$NSX_MGR/policy/api/v1/infra/virtual-machines/$VM_ID" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --argjson tags "$MERGED_TAGS" '{tags:$tags}')" \
    > /dev/null

done

echo
echo "✅ VM tag restore complete"
