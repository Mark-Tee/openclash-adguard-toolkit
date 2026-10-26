# Sanitized Case Study

This case study is intentionally stripped of router addresses, provider names,
subscription URLs, and credentials.

## Starting topology

```text
dnsmasq :53 -> AdGuard :5454 -> multiple public DNS resolvers in parallel
OpenClash DNS :7874 -> not used by the client DNS path
```

Observed symptoms:

- foreign domains returned real IPs through AdGuard
- OpenClash DNS returned Fake-IP for the same domains
- first domestic lookups sometimes took 500-600 ms
- Dota 2 China accepted a match and remained stuck at Connecting

## Root problems

1. AdGuard bypassed the OpenClash DNS policy.
2. AdGuard bootstrap DNS contained dead ISP resolvers.
3. OpenClash was missing direct rules for Steam China/WMSJ domains.
4. Raw game UDP traffic had no explicit direct-path safeguard.
5. Subscription information placeholders were treated as healthy automatic
   nodes, causing GitHub and YouTube traffic to select a non-working entry.

## Applied changes

- AdGuard upstream changed to the local OpenClash DNS listener.
- AdGuard bootstrap DNS replaced with responsive domestic resolvers.
- Steam/Dota China domains added as top-priority direct rules.
- UDP destination ports `27000-29000` added as a direct game fallback.
- Steam/Dota domains added to AdGuard user-rule exceptions.
- Router process matching disabled when no process rules were present.
- URL-test and fallback intervals reduced to 600 seconds with a 50 ms tolerance.
- Information placeholders removed from automatic group member lists.

## Verification model

- blocked domain -> `0.0.0.0`
- domestic domain -> real Chinese IP
- foreign domain -> Fake-IP from OpenClash
- Steam China connection log -> `DIRECT`
- UDP game-port log -> `DIRECT`
- GitHub/YouTube -> proxy chain unchanged
- SafeSearch domain and canonical domain -> same Fake-IP mapping

Fake-IP alone was not treated as success or failure. Live connection rules and
chains were authoritative.
