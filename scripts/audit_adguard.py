#!/usr/bin/env python3
"""Print non-secret AdGuard Home configuration and filter facts."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from urllib.parse import urlsplit

import yaml


def host_of(value: object) -> str | None:
    if not isinstance(value, str) or not value:
        return None
    try:
        return urlsplit(value).hostname
    except ValueError:
        return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("config", type=Path)
    args = parser.parse_args()

    data = yaml.safe_load(args.config.read_text(encoding="utf-8", errors="replace"))
    if not isinstance(data, dict):
        raise SystemExit("AdGuard config is not a YAML mapping")

    dns = data.get("dns") or {}
    filtering = data.get("filtering") or {}
    filters = []
    for item in data.get("filters") or []:
        if not isinstance(item, dict):
            continue
        filters.append(
            {
                "name": item.get("name"),
                "enabled": item.get("enabled"),
                "url_host": host_of(item.get("url")),
                "url_has_query": bool(
                    isinstance(item.get("url"), str) and "?" in item["url"]
                ),
            }
        )

    output = {
        "dns": {
            key: dns.get(key)
            for key in (
                "port",
                "upstream_dns",
                "upstream_mode",
                "bootstrap_dns",
                "fallback_dns",
                "cache_enabled",
                "cache_size",
                "cache_ttl_min",
                "cache_ttl_max",
                "cache_optimistic",
                "aaaa_disabled",
                "enable_dnssec",
                "edns_client_subnet",
                "ratelimit",
            )
        },
        "filtering": {
            "filtering_enabled": filtering.get("filtering_enabled"),
            "protection_enabled": filtering.get("protection_enabled"),
            "safebrowsing_enabled": filtering.get("safebrowsing_enabled"),
            "parental_enabled": filtering.get("parental_enabled"),
            "safe_search": filtering.get("safe_search"),
            "filters_update_interval": filtering.get("filters_update_interval"),
            "blocking_mode": filtering.get("blocking_mode"),
        },
        "filters": filters,
        "whitelist_filter_count": len(data.get("whitelist_filters") or []),
        "user_rule_count": len(data.get("user_rules") or []),
        "querylog": {
            key: (data.get("querylog") or {}).get(key)
            for key in ("enabled", "file_enabled", "interval", "size_memory")
        },
        "statistics": {
            key: (data.get("statistics") or {}).get(key)
            for key in ("enabled", "interval")
        },
        "tls_enabled": (data.get("tls") or {}).get("enabled"),
        "http_address": (data.get("http") or {}).get("address"),
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
