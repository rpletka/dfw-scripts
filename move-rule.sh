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

echo "=== Move NSX DFW Rule Between Sections ==="

########################################
# Prompt inputs
########################################
read -r -p "Rule path (full /infra/.../rules/<id>): " RULE_PATH
read -r -p "Target section path (/infra/.../security-policies/<section>): " TARGET_SECTION

########################################
# Validate
########################################
if [[ ! "$RULE_PATH" =~ /rules/ ]]; then
  echo "❌ Must provide full rule path"
  exit 1
fi

RULE_ID="$(basename "$RULE_PATH")"
TARGET_RULE_PATH="$TARGET_SECTION/rules/$RULE_ID"

RULE_URL="https://$NSX_MGR/policy/api/v1$RULE_PATH"
TARGET_URL="https://$NSX_MGR/policy/api/v1$TARGET_RULE_PATH"

echo
echo "Moving rule:"
echo "  FROM: $RULE_PATH"
echo "  TO:   $TARGET_RULE_PATH"
echo

read -r -p "Type MOVE to confirm: " CONFIRM
[[ "$CONFIRM" == "MOVE" ]] || { echo "❌ Aborted"; exit 1; }

########################################
# Export + sanitize rule
########################################
TMP=$(mktemp)

echo "⬇️ Exporting rule..."

curl -sS -k -u "${NSX_USER}:${NSX_PASS}" "$RULE_URL" \
| jq '
walk(
  if type=="object" then
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
      .sequence_number,
      .rule_id,
      .marked_for_delete,
      .overridden
    )
  else .
  end
)' > "$TMP"

########################################
# Create in target section
########################################
echo "⬆️ Creating rule in target section..."

curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -d @"$TMP" \
  "$TARGET_URL"

########################################
# Delete original
########################################
echo "🗑️ Deleting original rule..."

curl -sS -k -u "${NSX_USER}:${NSX_PASS}" \
  -X DELETE \
  "$RULE_URL"

rm -f "$TMP"

echo "✅ Rule moved successfully"

