# MetaCubeXD and Proxy Groups

MetaCubeXD is the official Mihomo dashboard. The dashboard itself rarely needs
tuning; inspect the runtime configuration it displays.

## Useful read-only checks

```text
GET /configs
GET /proxies
GET /providers/proxies
GET /connections
GET /version
```

Use the external-controller secret from the router configuration. Never print
the secret.

## Safe router defaults

- `find-process-mode: off` when no process-based rules are present.
- URL-test and fallback interval: 300-900 seconds.
- URL-test tolerance: 50-150 ms.
- Keep `unified-delay: true` and `tcp-concurrent: true`.
- Keep rule mode and an explicit FINAL/MATCH policy.

OpenClash can persist these values through:

```text
openclash.config.find_process_mode
openclash.config.urltest_interval_mod
openclash.config.tolerance
```

Restart OpenClash after changing them and inspect the generated runtime YAML.

## Information pseudo-nodes

Paid subscriptions often insert entries for:

- remaining traffic
- reset date
- plan expiry
- website or customer-service URL
- client upgrade notices
- "only these nodes" instructional entries

They may answer latency probes and therefore be selected by URL-test groups.
This can make GitHub, YouTube, or other sites fail even though the node list
shows all entries as healthy.

Do not assume a green latency result means a usable proxy. Check the actual
connection chain and remove information entries from `url-test` and `fallback`
group member lists.

Use `scripts/filter_pseudo_nodes.rb` as a custom-overwrite step. It removes
matching names only from automatic groups; it does not delete proxy definitions
or rules.

In `/etc/openclash/custom/openclash_custom_overwrite.sh`, call it after the
configuration has been generated:

```sh
ruby /path/to/filter_pseudo_nodes.rb "$CONFIG_FILE" >> "$LOG_FILE" 2>&1
```

Validate the resulting runtime YAML with the installed Mihomo core before
relying on it:

```sh
SAFE_PATHS=/etc/openclash:/usr/share/openclash:/tmp \
  /etc/openclash/clash -t -d /etc/openclash -f /tmp/candidate.yaml
```
