# Architecture and Invariants

## Expected DNS path

```text
client
  -> dnsmasq :53
  -> AdGuard Home :5454
  -> OpenClash/Mihomo DNS :7874
  -> configured domestic DoH/DoT
```

Port numbers are examples. Resolve them from the live system; never assume that
53, 5454, or 7874 are universally correct.

## Required checks

1. Find the listening process for port 53.
2. Find the active AdGuard config and DNS listen port.
3. Find the active OpenClash YAML and DNS listen port.
4. Confirm dnsmasq forwards to AdGuard.
5. Confirm AdGuard forwards to OpenClash, not directly to public resolvers.
6. Confirm OpenClash does not forward back to AdGuard.
7. Confirm the active OpenClash config and subscription binding.

Useful read-only checks:

```sh
/etc/init.d/openclash status
/etc/init.d/dnsmasq status
/etc/init.d/AdGuardHome status
netstat -lnptu
uci -q get dhcp.@dnsmasq[0].server
uci -q get openclash.config.config_path
uci -q get openclash.config.en_mode
uci -q get openclash.config.dns_port
```

Do not print complete UCI or YAML output without redaction.

## Routing invariants

- Keep OpenClash in rule mode.
- Keep private/LAN and known China traffic direct.
- Route unresolved/foreign traffic through the user's chosen proxy group.
- Do not equate "Fake-IP" with "proxy traffic". Fake-IP is a DNS delivery
  mechanism; the connection rule and chain determine the actual route.
- Validate with both DNS answers and live connection records.
- For a domestic game, check domain rules and raw UDP/IP destination rules.

## Useful interpretations

- Domestic domain returning a real China IP: usually direct-ready.
- Foreign domain returning `198.18.x.x`: usually eligible for rule-based
  proxying, not proof that a node is already carrying traffic.
- Ad domain returning `0.0.0.0`: AdGuard filtering is active.
- AdGuard and OpenClash each returning different answers: AdGuard may be
  bypassing the OpenClash DNS policy or caching a previous answer.
- Repeated bootstrap DNS errors plus slow cold lookups: replace dead bootstrap
  resolvers before changing routing rules.

## Filter-list review

Prefer a small set of maintained, non-duplicative sources:

- one general-purpose DNS blocklist
- one region-specific list when needed
- one anti-push-notification list if the user wants it
- one phishing/malware list

Review rule count, last update time, memory use, and false-positive risk. A
large list is not automatically better. Add explicit exceptions for services
that must remain reachable.

## Multiple AdGuard instances

Two configs and two init scripts can coexist. Determine which instance owns the
used web and DNS ports before editing. Disabling an unused instance can save
memory, but it is a service behavior change and requires explicit user approval.
