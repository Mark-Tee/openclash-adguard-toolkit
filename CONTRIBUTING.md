# Contributing

Contributions are welcome when they improve safety, reproducibility, or
diagnostics.

## Before opening a pull request

1. Run the repository checks:

   ```bash
   python -m compileall -q scripts tests
   python -m unittest discover -s tests -v
   ruby -c scripts/filter_pseudo_nodes.rb
   bash -n scripts/*.sh
   ```

2. Keep examples parameterized. Do not add real router addresses, provider
   names, subscription URLs, credentials, private keys, or raw configs.
3. Describe the observed symptom, the evidence, the changed files, and the
   validation performed.
4. Preserve read-only-first and backup-before-write behavior.

## Scope

In scope:

- OpenWrt / iStoreOS
- OpenClash / Mihomo
- AdGuard Home
- DNS, Fake-IP, routing, and service-health diagnostics
- safe helper scripts and Codex instructions

Out of scope:

- bypassing access controls
- bulk scraping
- distributing subscriptions or proxy credentials
- changing unrelated system network, DHCP, firewall, or Wi-Fi settings
