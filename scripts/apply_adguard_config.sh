#!/bin/sh
set -eu

# Run on the OpenWrt router, not on the Windows client.
# Usage:
#   I_UNDERSTAND_SAFEOPS_WRITE=1 sh apply_adguard_config.sh \
#     /tmp/AdGuardHome.candidate.yaml

[ "${I_UNDERSTAND_SAFEOPS_WRITE:-}" = "1" ] || {
  echo "Refusing write without I_UNDERSTAND_SAFEOPS_WRITE=1" >&2
  exit 1
}

CANDIDATE="${1:-}"
[ -f "$CANDIDATE" ] || {
  echo "Candidate config does not exist: $CANDIDATE" >&2
  exit 1
}

CONFIG="${ADGUARD_CONFIG:-/etc/AdGuardHome.yaml}"
SERVICE="${ADGUARD_SERVICE:-/etc/init.d/AdGuardHome}"
BACKUP_ROOT="${ADGUARD_BACKUP_ROOT:-/etc/AdGuardHome/safeops-backups}"
CHECK_DIR="${ADGUARD_CHECK_DIR:-/tmp/adguard-safeops-check}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$CHECK_DIR"
chmod 700 "$BACKUP_DIR" "$CHECK_DIR"
cp -p "$CONFIG" "$BACKUP_DIR/AdGuardHome.yaml"

rollback() {
  echo "Rolling back AdGuard configuration" >&2
  cp -p "$BACKUP_DIR/AdGuardHome.yaml" "$CONFIG"
  chmod 600 "$CONFIG"
  "$SERVICE" restart || true
}

/usr/bin/AdGuardHome --check-config -c "$CANDIDATE" -w "$CHECK_DIR"

new_config="$CONFIG.safeops-new"
cp -p "$CANDIDATE" "$new_config"
chmod 600 "$new_config"
mv "$new_config" "$CONFIG"

if ! "$SERVICE" restart; then
  rollback
  exit 1
fi

ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
  if "$SERVICE" status >/dev/null 2>&1; then
    ready=1
    break
  fi
  sleep 1
done

if [ "$ready" != "1" ]; then
  rollback
  exit 1
fi

echo "APPLY_OK"
echo "backup=$BACKUP_DIR"
echo "config=$CONFIG"
echo "service=running"
