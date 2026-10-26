#!/usr/bin/env python3
"""Create a validated AdGuard candidate without exposing secrets."""

from __future__ import annotations

import argparse
import copy
import hashlib
from pathlib import Path

import yaml


def read_allowlist(path: Path) -> list[str]:
    rules = []
    for line in path.read_text(encoding="utf-8").splitlines():
        rule = line.strip()
        if rule and not rule.startswith("#"):
            rules.append(rule)
    return rules


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("allowlist", type=Path)
    parser.add_argument(
        "--bootstrap",
        default="223.5.5.5,119.29.29.29",
        help="Comma-separated bootstrap DNS IPs",
    )
    args = parser.parse_args()

    original = yaml.safe_load(args.input.read_text(encoding="utf-8"))
    if not isinstance(original, dict) or not isinstance(original.get("dns"), dict):
        raise SystemExit("Input does not contain a dns mapping")

    candidate = copy.deepcopy(original)
    bootstrap = [item.strip() for item in args.bootstrap.split(",") if item.strip()]
    if not bootstrap:
        raise SystemExit("Bootstrap DNS list is empty")
    candidate["dns"]["bootstrap_dns"] = bootstrap

    existing = [
        item.strip()
        for item in (original.get("user_rules") or [])
        if isinstance(item, str) and item.strip()
    ]
    allowlist = read_allowlist(args.allowlist)
    candidate["user_rules"] = list(dict.fromkeys(existing + allowlist))

    expected = copy.deepcopy(original)
    expected["dns"]["bootstrap_dns"] = bootstrap
    expected["user_rules"] = list(dict.fromkeys(existing + allowlist))
    if candidate != expected:
        raise SystemExit("Unexpected candidate mutation")

    args.output.write_text(
        yaml.safe_dump(candidate, allow_unicode=True, sort_keys=False, width=1000),
        encoding="utf-8",
        newline="\n",
    )
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    print(f"bootstrap_dns={bootstrap}")
    print(f"existing_user_rules={len(existing)}")
    print(f"allowlist_rules_added={len(allowlist)}")
    print(f"user_rules_total={len(candidate['user_rules'])}")
    print(f"candidate_sha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
