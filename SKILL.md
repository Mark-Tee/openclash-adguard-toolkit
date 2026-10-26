---
name: openclash-adguard-optimizer
description: Safely audit and optimize an OpenWrt, iStoreOS, OpenClash/Mihomo, and AdGuard Home DNS stack. Use for DNS topology problems, domestic/foreign routing leaks, Fake-IP issues, game connection failures, filter-list review, or reusable router optimization.
---

# OpenClash + AdGuard Optimizer

Use this skill when a router runs OpenClash/Mihomo with AdGuard Home or a similar
DNS filtering layer, and the user wants faster DNS, correct domestic/foreign
routing, safer filter lists, or a reproducible optimization.

## Safety invariants

1. Start read-only. Identify the active AdGuard config, active OpenClash YAML,
   DNS listeners, dnsmasq forwarders, and service status before changing files.
2. Never edit `/etc/config/network`, `/etc/config/dhcp`, or `/etc/config/firewall`
   for a normal DNS or proxy optimization.
3. Back up every config and custom-rule file before a write. Keep a tested
   rollback path.
4. Never commit subscription URLs, proxy credentials, password hashes, API
   secrets, private keys, query logs, or raw router configs to this repository.
5. Do not enable more large blocklists just to increase the rule count. Review
   overlap, false-positive risk, memory use, and maintenance status first.
6. Validate a candidate with the application's own config checker before
   restarting a service.

## Working model

The preferred topology is:

```text
LAN client -> dnsmasq :53 -> AdGuard Home -> OpenClash DNS -> domestic DoH/DoT
                                      |
                                      +-> Mihomo Fake-IP and routing rules
```

AdGuard Home should filter DNS and forward to OpenClash. It should not forward
directly to public resolvers when that would bypass OpenClash's domestic/foreign
DNS policy. Verify that OpenClash does not forward back to AdGuard, which would
create a loop.

Keep `mode: rule`, preserve private/domestic direct rules, and use the final
`MATCH` rule for otherwise-unclassified traffic. Validate the actual connection
chain rather than assuming that a Fake-IP answer means proxy traffic.

## Workflow

1. Read [references/architecture.md](references/architecture.md) for topology
   checks and invariants.
2. Run read-only audits:
   - `python scripts/audit_adguard.py /path/to/AdGuardHome.yaml`
   - `python scripts/audit_openclash.py /path/to/active-openclash.yaml`
   - On Windows, `scripts/Inspect-AdGuard.ps1 -BaseUrl http://ROUTER:3000`
     collects a redacted AdGuard API snapshot.
3. Confirm the DNS chain, port ownership, active config, subscription binding,
   and whether multiple configs or multiple AdGuard instances exist.
4. Read [references/runbook.md](references/runbook.md) before any write.
5. Generate candidates with the scripts in `scripts/`. Inspect every diff.
6. Validate candidates with `--check-config` or the Mihomo core test flag.
7. Apply with backup and automatic rollback. Restart only the affected service.
8. Verify DNS answers, actual Mihomo rule/chains, domestic routing, external
   routing, game traffic, web latency, and service health.
9. Report changed files, backup path, validation evidence, and rollback steps.

## Optimization defaults

Use the following as defaults when the existing setup does not provide a better
reason:

- AdGuard upstream: the local OpenClash DNS listener, for example
  `127.0.0.1:7874`.
- Bootstrap DNS: two responsive plain-DNS IPs from different providers. Do not
  keep known-dead ISP resolvers.
- Keep AAAA disabled when the LAN has no usable IPv6 policy through the proxy.
- Keep AdGuard cache enabled with a modest size and optimistic caching.
- Keep query and statistics retention short on flash-backed routers.
- On routers without process-based rules, prefer `find-process-mode: off`.
- Keep URL-test and fallback intervals in the range of 300-900 seconds and use
  a tolerance to avoid unnecessary node flapping.
- Remove subscription information placeholders such as plan, traffic, expiry,
  website, upgrade-notice, and "only these nodes" entries from automatic
  latency groups. Remove the placeholder proxy definitions and every group
  reference too; a selector can otherwise persist a non-working placeholder.
- If a direct-rule domain still resolves to Fake-IP and the log shows
  `DIRECT ... 198.18.x.x` timeouts, add that direct domain to `fake-ip-filter`
  and clear dnsmasq/client caches. Do not send domestic services through the
  node just to avoid a DNS-mode mismatch.
- Verify the AdGuard init service points at the active config, work directory,
  and DNS/UI ports. A manually started second process is not a reliable boot
  configuration.
- If Steam Community is slow while account/game traffic works, inspect actual
  chains instead of assuming a Steam outage. A common split is to keep
  `steamcontent.com`, Steam CM hosts, client downloads, and game UDP direct while
  routing only Steam website/CDN domains through a dedicated selectable group.
  Benchmark a large community asset as well as latency, because a node with a
  healthy 204 probe can still have poor CDN throughput.
- Use curated, maintained filter sources. Avoid stacking several overlapping
  multi-hundred-thousand-rule lists.
- Add explicit DNS exceptions for game/service domains that must not be
  false-positive blocked.
- For Steam/Dota 2 China, use
  [assets/openclash-steam-dota-direct.list](assets/openclash-steam-dota-direct.list)
  and [assets/adguard-steam-dota-allowlist.txt](assets/adguard-steam-dota-allowlist.txt).
  Validate the actual UDP destination before widening port rules.

## Authentication and captures

Do not ask the user to paste a router password or AdGuard password into chat.
Use an interactive local helper that keeps credentials in memory:

- `scripts/Bootstrap-RouterSshKey.ps1` installs a temporary key for SSH-based
  read-only diagnostics.
- `scripts/Inspect-AdGuard.ps1` logs in interactively and saves a redacted
  snapshot without query-log contents.

Remove temporary keys and sensitive local captures when the task is complete.

## References

- [Architecture and invariants](references/architecture.md)
- [Change runbook](references/runbook.md)
- [Troubleshooting](references/troubleshooting.md)
- [MetaCubeXD and proxy groups](references/metacubexd.md)
- [Sources and licenses](references/sources.md)
- [Sanitized case study](references/case-study.md)
