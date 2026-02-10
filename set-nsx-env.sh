#!/usr/bin/env bash

echo "=== NSX Login Setup ==="

DEFAULT_MGR="nsx-t-mgr.far-away.galaxy"
DEFAULT_USER="admin"

printf "NSX Manager [%s]: " "$DEFAULT_MGR"
read NSX_MGR
NSX_MGR=${NSX_MGR:-$DEFAULT_MGR}

printf "Username [%s]: " "$DEFAULT_USER"
read NSX_USER
NSX_USER=${NSX_USER:-$DEFAULT_USER}

printf "Password: "
stty -echo
read NSX_PASS
stty echo
echo

export NSX_MGR
export NSX_USER
export NSX_PASS

nsxapi() {
  curl -sS -k -u "${NSX_USER}:${NSX_PASS}" "$@"
}
export -f nsxapi 2>/dev/null || true

echo
echo "✅ Ready"
echo "Example:"
echo "nsxapi https://\$NSX_MGR/policy/api/v1/infra"

