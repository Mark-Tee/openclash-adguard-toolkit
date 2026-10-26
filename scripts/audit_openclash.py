#!/usr/bin/env python3
"""Print non-secret OpenClash/Mihomo DNS, rules, and group facts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import yaml


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("config", type=Path)
    args = parser.parse_args()

    data = yaml.safe_load(args.config.read_text(encoding="utf-8", errors="replace"))
    if not isinstance(data, dict):
        raise SystemExit("OpenClash config is not a YAML mapping")

    dns = data.get("dns") or {}
    rules = data.get("rules") or []
    groups = data.get("proxy-groups") or []
    providers = data.get("rule-providers") or {}

    dns_keys = (
        "enable",
        "listen",
        "ipv6",
        "enhanced-mode",
        "fake-ip-range",
        "fake-ip-filter",
        "default-nameserver",
        "nameserver",
        "fallback",
        "fallback-filter",
        "proxy-server-nameserver",
        "respect-rules",
    )
    provider_summary = {
        name: {
            key: value
            for key, value in config.items()
            if key in {"type", "behavior", "format", "interval"}
        }
        for name, config in providers.items()
        if isinstance(config, dict)
    }

    output = {
        "root": {
            key: data.get(key)
            for key in (
                "mode",
                "log-level",
                "ipv6",
                "unified-delay",
                "tcp-concurrent",
                "find-process-mode",
            )
            if key in data
        },
        "dns": {key: dns.get(key) for key in dns_keys if key in dns},
        "proxy_count": len(data.get("proxies") or []),
        "proxy_groups": [
            {
                key: group.get(key)
                for key in ("name", "type", "interval", "tolerance", "lazy")
                if key in group
            }
            for group in groups
            if isinstance(group, dict)
        ],
        "rule_provider_count": len(provider_summary),
        "rule_count": len(rules),
        "rules_tail": rules[-20:],
        "match_rules": [
            rule for rule in rules if isinstance(rule, str) and rule.startswith("MATCH,")
        ],
        "domestic_direct_rules": [
            rule
            for rule in rules
            if isinstance(rule, str)
            and ("GEOSITE,cn" in rule or "GEOIP,CN" in rule or "GEOSITE,private" in rule)
        ],
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
