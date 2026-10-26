# Repository Instructions

Read `SKILL.md` before performing network changes.

- Do not add real router addresses, credentials, subscription URLs, proxy
  definitions, password hashes, private keys, or unredacted configs.
- Keep reusable scripts parameterized. Do not hardcode a specific LAN subnet or
  provider.
- Run the relevant script syntax checks and `scripts/quick_validate.py` after
  editing the skill.
- Treat `references/` as supporting guidance; load only the file needed for the
  current task.
- Back up and verify rollback before applying changes on a live router.
- Never modify OpenWrt network, DHCP, firewall, Wi-Fi, or interface config as part
  of this workflow.
