#!/usr/bin/env bash
set -euo pipefail

########################################
# Verify environment
########################################
if [[ -z "${NSX_MGR:-}" || -z "${NSX_USER:-}" || -z "${NSX_PASS:-}" ]]; then
  echo "❌ NSX environment not loaded."
  echo "Run: source set-nsx-env.sh"
  exit 1
fi

echo "=== Import NSX Policy (bottom of category) ==="

########################################
# JSON file
########################################
JSON_FILE="${1:-}"

if [[ -z "$JSON_FILE" ]]; then
  read -r -p "Policy JSON file: " JSON_FILE
fi

[[ -f "$JSON_FILE" ]] || { echo "❌ File not found"; exit 1; }

########################################
# Preserve display name
########################################
DISPLAY_NAME=$(jq -r '.display_name' "$JSON_FILE")

########################################
# ID = filename + date
########################################
BASENAME="$(basename "$JSON_FILE" .json)"
DATE_SUFFIX=$(date +%Y%m%d)
NEW_ID="${BASENAME}-${DATE_SUFFIX}"

echo "Display name : $DISPLAY_NAME"
echo "New ID       : $NEW_ID"

########################################
# Sanitize JSON recursively
########################################
TMP_JSON=$(mktemp)

jq \
  --arg id "$NEW_ID" \
  --arg name "$DISPLAY_NAME" \
  '
  walk(
    if type == "object" then
      del(
        ._links,
        ._path,
        ._revision,
        ._create_time,
        ._create_user,
        ._last_modified_time,
        ._last_modified_user,
        ._system_owned,
        .parent_path,
        .relative_path,
        .unique_id,
        .realization_id,
        .owner_id,
        .marked_for_delete,
        .overridden,
        .sequence_number,
        .internal_sequence_number,
        .rule_id
      )
    else .
    end
  )
  | .id = $id
  | .display_name = $name
  ' "$JSON_FILE" > "$TMP_JSON"

########################################
# Create policy first
########################################
POLICY_URL="https://$NSX_MGR/policy/api/v1/infra/domains/default/security-policies/$NEW_ID"

echo "⬆️  Creating policy..."

curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d @"$TMP_JSON" \
  "$POLICY_URL"

########################################
# Move AFTER last
########################################
curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$POLICY_URL?action=revise&operation=insert_bottom"


rm -f "$TMP_JSON"

echo "✅ Import + positioned at bottom of Application"

