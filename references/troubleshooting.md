# Troubleshooting

## AdGuard bypasses OpenClash

Symptoms:

- AdGuard upstream list contains public resolvers
- foreign domains return real IPs while OpenClash DNS returns `198.18.x.x`
- domestic and foreign egress paths look identical

Action:

1. Confirm no DNS loop.
2. Back up the AdGuard config.
3. Point AdGuard upstream to the local OpenClash DNS listener.
4. Restart AdGuard to clear its cache.
5. Verify domestic, foreign, and blocked domains.

## Slow first DNS query

Check bootstrap DNS health. Remove dead ISP resolvers and unreachable public
resolvers, then use two responsive resolver IPs. Do not confuse a warm cache with
a fast upstream.

## Dota 2 or Steam China stuck at Connecting

Likely causes:

- Steam China/WMSJ domains are missing from direct rules
- game UDP traffic hits an unsupported or incompatible proxy node
- a DNS blocklist false-positive blocks a service domain

Actions:

- Add Steam/Dota China domains as top-priority direct rules.
- Add a UDP destination-port bypass only when the game port is known.
- Add DNS allowlist exceptions for the same service.
- Verify the live Mihomo log shows `DIRECT` for the actual connection.

Do not broaden a rule to all traffic. Prefer domain, source, destination IP, or
port constraints.

## Steam Community loads slowly while Dota 2 works

Check the live connection chains for all of these separately:

- `steamcommunity.com`
- `community.akamai.steamstatic.com`
- `avatars.steamstatic.com`
- `images.steamusercontent.com`
- `api.steampowered.com`
- `login.steampowered.com`

A page can return `200` while its scripts, styles, or images are still routed
`DIRECT` and timing out. `403` from a Steam CDN root is not conclusive; test an
actual CSS or JavaScript asset.

Do not switch the global selector just because one Steam asset is slow. Create a
dedicated Steam website group, keep game downloads, Steam CM, and game UDP
direct, and compare nodes with a large real asset rather than latency alone.
`scripts/add_steam_web_group.rb` creates that split without hardcoding a provider.

After a rule restart, verify both the rule target and an observed connection
chain. Also restart Steam so its CEF web cache does not keep an old failing path.

### Error code -105 after changing the network path

If the router or client changes its egress while Steam is running, the embedded
browser can keep failing with `Error Code: -105` even though ordinary HTTP tests
work. Finish all node or VPN changes first, fully exit Steam, and start it again.
Valve tracks this reconnect behavior in
[steam-for-linux#12518](https://github.com/ValveSoftware/steam-for-linux/issues/12518).

Before clearing the CEF cache, verify that `store.steampowered.com`,
`login.steampowered.com`, and the API endpoint all work from the router. A cache
change is a separate troubleshooting step and should not replace checking the
live connection chain.

## Fake-IP looks wrong

Fake-IP is not itself a fault. Check the connection chain. A Fake-IP address may
still route DIRECT after Mihomo maps it back to the domain.

## DIRECT domains time out at 198.18.x.x

This is different from a normal Fake-IP lookup. If a domain has an explicit
`DIRECT` rule but the log shows `dial DIRECT ... 198.18.x.x:443: i/o timeout`,
the direct path is being given the synthetic address instead of a real origin.

Action:

1. Query the OpenClash DNS listener directly and confirm the domain returns
   `198.18.x.x`.
2. Add the direct domain suffix to `dns.fake-ip-filter` in blacklist mode.
3. Validate and restart Mihomo.
4. Flush the dnsmasq cache and the client DNS cache so stale Fake-IP answers do
   not keep the failure alive.
5. Confirm the direct domain now returns a real IP while proxy domains still
   return Fake-IP.

`scripts/add_fakeip_filter_entries.rb` performs step 2 without assuming a
provider or router address.

## Two AdGuard instances

Check both config paths and listening ports. The one answering the used UI and
DNS ports is the active instance. Do not assume the init script name matches the
active process. Verify `/etc/config/adguardhome` points to the active config and
work directory, then stop the manual instance and start the init service. After
the change, require exactly one AdGuardHome process, DNS on the port used by
dnsmasq, and an HTTP response from the configured UI port.

## Domestic traffic uses the node

Check:

- final MATCH rule policy
- explicit direct rules
- GEOIP/GEOSITE behavior
- multiple config/subscription switching
- proxy DNS policy or bypassed DNS path

Use public-IP egress comparison and live chains, not only rule text.

## Slow or bloated filtering

Check number of enabled filters, overlap, last update time, process RSS, data
directory size, and log growth. Do not solve rule overlap by adding another large
list.
