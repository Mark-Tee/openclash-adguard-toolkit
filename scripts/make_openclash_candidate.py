#!/usr/bin/env python3
"""Merge custom direct rules at the top of an OpenClash YAML candidate."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path

import yaml


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("active_config", type=Path)
    parser.add_argument("custom_rules", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    data = yaml.safe_load(args.active_config.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise SystemExit("Active config is not a YAML mapping")

    custom = yaml.safe_load(args.custom_rules.read_text(encoding="utf-8"))
    if isinstance(custom, dict):
        custom = custom.get("rules")
    if not isinstance(custom, list) or not all(isinstance(x, str) for x in custom):
        raise SystemExit("Custom rules must be a YAML list or a mapping with rules")

    original_rules = data.get("rules")
    if not isinstance(original_rules, list):
        raise SystemExit("Active config does not contain a rules list")
    if not any(isinstance(x, str) and x.startswith("MATCH,") for x in original_rules):
        raise SystemExit("Active config has no final MATCH rule")

    data["rules"] = list(dict.fromkeys(custom + original_rules))
    args.output.write_text(
        yaml.safe_dump(data, allow_unicode=True, sort_keys=False, width=1000),
        encoding="utf-8",
        newline="\n",
    )

    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    print(f"custom_rules={len(custom)}")
    print(f"resulting_rules={len(data['rules'])}")
    print(f"final_rule={data['rules'][-1]}")
    print(f"candidate_sha256={digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
