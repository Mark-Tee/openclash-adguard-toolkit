# Change Runbook

Use this before any live write.

## 1. Establish context

Record:

- router model, firmware, and architecture
- active AdGuard config path and DNS/UI ports
- active OpenClash config path, mode, DNS port, and subscription binding
- commands used for read-only inspection
- backout path

## 2. Back up

Back up at least:

```text
/etc/AdGuardHome.yaml
/etc/config/openclash
/etc/openclash/<active-runtime>.yaml
/etc/openclash/config/<active-source>.yaml
/etc/openclash/custom/
```

Use a timestamped directory and restrictive permissions. Do not overwrite an
older backup.

## 3. Generate a candidate

Modify the candidate only; leave the live file untouched.

For AdGuard:

```powershell
python scripts/make_adguard_candidate.py input.yaml output.yaml allowlist.txt
```

For OpenClash:

```powershell
python scripts/make_openclash_candidate.py active.yaml custom-rules.list output.yaml
```

Inspect the diff and verify that unrelated fields, proxies, groups, providers,
and subscription state were preserved.

## 4. Validate

AdGuard:

```sh
/usr/bin/AdGuardHome --check-config -c /tmp/candidate.yaml -w /tmp/adguard-check
```

Mihomo/OpenClash:

```sh
/etc/openclash/clash -t -d /etc/openclash -f /tmp/candidate.yaml
```

Do not restart the service when either command fails.

## 5. Apply and verify

Apply with an automatic rollback script. Restart only the changed service.

Verify:

- service status
- web UI reachability
- DNS answers for a domestic domain, a foreign domain, and a known blocked domain
- actual Mihomo rule and chain for representative connections
- domestic and foreign public-IP paths
- normal HTTPS responses
- game/service-critical exceptions

For a Fake-IP setup, do not use a Fake-IP answer as the route proof. Use the
Mihomo connection API or logs.

## 6. Report and clean up

Report:

- files changed
- backup path
- validation output
- rollback command
- any temporary keys or sensitive captures that still exist

Remove temporary remote scripts and candidates after success. Keep the tested
rollback backup until the user confirms the change.
