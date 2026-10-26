#!/bin/sh
set -eu

# Run on the OpenWrt router.
# Usage: I_UNDERSTAND_SAFEOPS_WRITE=1 sh apply_metacubex_settings.sh

[ "${I_UNDERSTAND_SAFEOPS_WRITE:-}" = "1" ] || {
  echo "Refusing write without I_UNDERSTAND_SAFEOPS_WRITE=1" >&2
  exit 1
}

CONFIG="${OPENCLASH_CONFIG:-/etc/config/openclash}"
SERVICE="${OPENCLASH_SERVICE:-/etc/init.d/openclash}"
BACKUP_ROOT="${BACKUP_ROOT:-/etc/openclash/safeops-backups}"
INTERVAL="${URLTEST_INTERVAL:-600}"
TOLERANCE="${URLTEST_TOLERANCE:-50}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$TIMESTAMP"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"
cp -p "$CONFIG" "$BACKUP_DIR/config-openclash"

rollback() {
  echo "Rolling back OpenClash UCI settings" >&2
  cp -p "$BACKUP_DIR/config-openclash" "$CONFIG"
  chmod 600 "$CONFIG"
  rm -f /tmp/openclash.change
  "$SERVICE" restart || true
}

uci set openclash.config.find_process_mode=off
uci set "openclash.config.urltest_interval_mod=$INTERVAL"
uci set "openclash.config.tolerance=$TOLERANCE"
uci commit openclash
rm -f /tmp/openclash.change

if ! "$SERVICE" restart; then
  rollback
  exit 1
fi

ready=0
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30; do
  secret=$(uci -q get openclash.config.dashboard_password || true)
  code=$(curl -sS -o /dev/null -w '%{http_code}' --max-time 2 \
    -H "Authorization: Bearer $secret" \
    http://127.0.0.1:9090/version 2>/dev/null || true)
  if [ "$code" = "200" ]; then
    ready=1
    break
  fi
  sleep 1
done

if [ "$ready" != "1" ]; then
  rollback
  exit 1
fi

config_path=$(uci -q get openclash.config.config_path || true)
runtime_config="/etc/openclash/$(basename "$config_path")"
if [ ! -f "$runtime_config" ] || ! ruby -ryaml -e '
  data = YAML.load_file(ARGV[0])
  groups = data.fetch("proxy-groups", [])
  targets = groups.select { |g| ["url-test", "fallback"].include?(g["type"]) }
  ok = !targets.empty? && targets.all? { |g| g["interval"].to_i == ARGV[1].to_i }
  ok &&= groups.select { |g| g["type"] == "url-test" }.all? do |g|
    g["tolerance"].to_i == ARGV[2].to_i
  end
  exit(ok ? 0 : 1)
' "$runtime_config" "$INTERVAL" "$TOLERANCE" >/dev/null 2>&1; then
  rollback
  exit 1
fi

echo "APPLY_OK"
echo "backup=$BACKUP_DIR"
echo "find_process_mode=off"
echo "urltest_interval=$INTERVAL"
echo "tolerance=$TOLERANCE"
