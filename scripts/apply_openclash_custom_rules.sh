#!/bin/sh
set -eu

# Run on the OpenWrt router, not on the Windows client.
# Usage:
#   I_UNDERSTAND_SAFEOPS_WRITE=1 sh apply_openclash_custom_rules.sh \
#     /tmp/openclash_custom_rules.list "DOMAIN-SUFFIX,steamchina.com,DIRECT"

[ "${I_UNDERSTAND_SAFEOPS_WRITE:-}" = "1" ] || {
  echo "Refusing write without I_UNDERSTAND_SAFEOPS_WRITE=1" >&2
  exit 1
}

CANDIDATE="${1:-}"
MARKER="${2:-}"
[ -n "$CANDIDATE" ] && [ -n "$MARKER" ] || {
  echo "Usage: $0 CUSTOM_RULES_FILE MARKER_RULE" >&2
  exit 1
}
[ -f "$CANDIDATE" ] || {
  echo "Candidate rules file does not exist: $CANDIDATE" >&2
  exit 1
}

OPENCLASH_CONFIG="${OPENCLASH_CONFIG:-/etc/config/openclash}"
CUSTOM_DIR="${CUSTOM_DIR:-/etc/openclash/custom}"
CUSTOM_RULES="${CUSTOM_RULES:-$CUSTOM_DIR/openclash_custom_rules.list}"
OPENCLASH_SERVICE="${OPENCLASH_SERVICE:-/etc/init.d/openclash}"
BACKUP_ROOT="${BACKUP_ROOT:-/etc/openclash/safeops-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$BACKUP_DIR" "$CUSTOM_DIR"
chmod 700 "$BACKUP_DIR" "$CUSTOM_DIR"
cp -p "$OPENCLASH_CONFIG" "$BACKUP_DIR/config-openclash"

old_enabled=$(uci -q get openclash.config.enable_custom_clash_rules || true)
had_custom_rules=0
if [ -f "$CUSTOM_RULES" ]; then
  cp -p "$CUSTOM_RULES" "$BACKUP_DIR/openclash_custom_rules.list"
  had_custom_rules=1
fi

rollback() {
  echo "Rolling back OpenClash custom rules" >&2
  cp -p "$BACKUP_DIR/config-openclash" "$OPENCLASH_CONFIG"
  if [ "$had_custom_rules" = "1" ]; then
    cp -p "$BACKUP_DIR/openclash_custom_rules.list" "$CUSTOM_RULES"
  else
    rm -f "$CUSTOM_RULES"
  fi
  if [ -n "${old_enabled:-}" ]; then
    uci set "openclash.config.enable_custom_clash_rules=$old_enabled"
  else
    uci delete openclash.config.enable_custom_clash_rules 2>/dev/null || true
  fi
  uci commit openclash
  rm -f /tmp/openclash.change
  "$OPENCLASH_SERVICE" restart || true
}

cp -p "$CANDIDATE" "$CUSTOM_RULES"
chmod 600 "$CUSTOM_RULES"
uci set openclash.config.enable_custom_clash_rules=1
uci commit openclash
rm -f /tmp/openclash.change

if ! "$OPENCLASH_SERVICE" restart; then
  rollback
  exit 1
fi

config_path=$(uci -q get openclash.config.config_path || true)
runtime_config="/etc/openclash/$(basename "$config_path")"

ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  secret=$(uci -q get openclash.config.dashboard_password || true)
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 \
    -H "Authorization: Bearer $secret" \
    http://127.0.0.1:9090/version 2>/dev/null || true)
  if [ "$code" = "200" ] && [ -f "$runtime_config" ] \
     && grep -qF "$MARKER" "$runtime_config"; then
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
echo "runtime_config=$runtime_config"
echo "marker_present=true"
