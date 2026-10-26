# Sources and Maintenance Status

Status checked 2026-10-24.

| Project | Purpose | License | Signal |
| --- | --- | --- | --- |
| [OpenClash](https://github.com/vernesong/OpenClash) | Router proxy plugin | MIT | Active, about 27.9k stars |
| [AdGuard Home](https://github.com/AdguardTeam/AdGuardHome) | Filtering DNS server | GPL-3.0 | Active, about 37.6k stars |
| [HostlistsRegistry](https://github.com/AdguardTeam/HostlistsRegistry) | Curated filter registry | GPL-3.0 | Active, updated daily |
| [MetaCubeXD](https://github.com/MetaCubeX/metacubexd) | Official Mihomo dashboard | MIT | Active, about 4.6k stars |
| [Aethersailor Rules](https://github.com/Aethersailor/Custom_OpenClash_Rules) | Community rule design | CC-BY-SA-4.0 | Active, about 6.7k stars |
| [anti-AD](https://github.com/privacy-protection-tools/anti-AD) | China-focused filter list | MIT | Active, about 10.9k stars |

Use official documentation first for behavior and schema. Use community rule
sets as reviewed design inputs, not as scripts to execute blindly.

For fields that change between core releases, inspect the `default.yaml`
bundled with the installed OpenClash package and validate against the actual
core with `clash -t`.
