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

command -v jq >/dev/null 2>&1 || {
  echo "❌ jq required"
  exit 1
}

DATE=$(date +%Y%m%d-%H%M%S)
BASE_DIR="nsx-backup-$DATE"

mkdir -p "$BASE_DIR"/{policies,groups,services,context-profiles,vms}

echo "📦 Backup → $BASE_DIR"
echo

safe_name() {
  echo "$1" | tr ' /' '__'
}

########################################
# Policies
########################################
echo "=== Policies ==="

curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/policy/api/v1/infra/domains/default/security-policies" \
| jq -c '
  (.results // [])
  | map(select(type=="object" and ((.is_default // false)==false) and ((._system_owned // false)==false)))
  | .[]
' | while IFS= read -r policy; do

  POLICY_PATH=$(echo "$policy" | jq -r '.path')
  NAME=$(echo "$policy" | jq -r '.display_name')
  CATEGORY=$(echo "$policy" | jq -r '.category')

  FILE="$BASE_DIR/policies/${CATEGORY}_$(safe_name "$NAME").json"

  echo "⬇️  $CATEGORY → $NAME"

  curl -sS -k -u "$NSX_USER:$NSX_PASS" \
  "https://$NSX_MGR/policy/api/v1$POLICY_PATH" \
  | jq '.' > "$FILE"

done

########################################
# Groups
########################################
echo "=== Groups ==="

curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/policy/api/v1/infra/domains/default/groups" \
| jq -c '
  (.results // [])
  | map(select(type=="object" and ((._system_owned // false)==false)))
  | .[]
' | while IFS= read -r obj; do
  NAME=$(echo "$obj" | jq -r '.display_name')
  echo "$obj" | jq '.' > "$BASE_DIR/groups/$(safe_name "$NAME").json"
done

########################################
# Services
########################################
echo "=== Services ==="

curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/policy/api/v1/infra/services" \
| jq -c '
  (.results // [])
  | map(select(type=="object" and ((._system_owned // false)==false)))
  | .[]
' | while IFS= read -r obj; do
  NAME=$(echo "$obj" | jq -r '.display_name')
  echo "$obj" | jq '.' > "$BASE_DIR/services/$(safe_name "$NAME").json"
done

########################################
# Context Profiles
########################################
echo "=== Context Profiles ==="

curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/policy/api/v1/infra/context-profiles" \
| jq -c '
  (.results // [])
  | map(select(type=="object" and ((._system_owned // false)==false)))
  | .[]
' | while IFS= read -r obj; do
  NAME=$(echo "$obj" | jq -r '.display_name')
  echo "$obj" | jq '.' > "$BASE_DIR/context-profiles/$(safe_name "$NAME").json"
done

########################################
# VMs + TAGS (Manager API)
########################################
echo "=== VM Tags ==="

VM_DATA=$(curl -sS -k -u "$NSX_USER:$NSX_PASS" \
"https://$NSX_MGR/api/v1/fabric/virtual-machines")

echo "$VM_DATA" | jq -c '
  (.results // [])
  | map(select((.tags // []) | length > 0))
  | .[]
' | while IFS= read -r vm; do

  NAME=$(echo "$vm" | jq -r '.display_name')
  echo "⬇️  VM (tagged) → $NAME"

  echo "$vm" | jq '.' > "$BASE_DIR/vms/$(safe_name "$NAME").json"

done

echo "$VM_DATA" | jq '
  (.results // [])
  | map(select((.tags // []) | length > 0))
  | map({name:.display_name,tags:.tags})
' > "$BASE_DIR/vm-tags-summary.json"

echo
echo "✅ Backup complete"
