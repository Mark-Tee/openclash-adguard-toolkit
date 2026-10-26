from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_required_public_files_exist(self) -> None:
        for relative in (
            "README.md",
            "LICENSE",
            "SECURITY.md",
            "CONTRIBUTING.md",
            "SKILL.md",
        ):
            self.assertTrue((ROOT / relative).is_file(), relative)

    def test_license_is_mit(self) -> None:
        license_text = (ROOT / "LICENSE").read_text(encoding="utf-8")
        self.assertIn("MIT License", license_text)

    def test_custom_rules_are_valid_yaml(self) -> None:
        path = ROOT / "assets" / "openclash-steam-dota-direct.list"
        data = yaml.safe_load(path.read_text(encoding="utf-8"))
        self.assertIsInstance(data, list)
        self.assertTrue(any(rule.startswith("AND,") for rule in data))

    def test_candidate_builder_keeps_match_last(self) -> None:
        import subprocess
        import sys

        active = {
            "rules": [
                "DOMAIN-SUFFIX,steamcontent.com,DIRECT",
                "MATCH,Proxy",
            ],
            "proxy-groups": [{"name": "Proxy", "type": "select", "proxies": ["DIRECT"]}],
            "proxies": [],
        }
        custom = {
            "rules": [
                "DOMAIN-SUFFIX,steamchina.com,DIRECT",
            ]
        }

        with tempfile.TemporaryDirectory() as temp_dir:
            temp = Path(temp_dir)
            active_path = temp / "active.yaml"
            custom_path = temp / "custom.yaml"
            output_path = temp / "candidate.yaml"
            active_path.write_text(yaml.safe_dump(active, sort_keys=False), encoding="utf-8")
            custom_path.write_text(yaml.safe_dump(custom, sort_keys=False), encoding="utf-8")

            subprocess.run(
                [
                    sys.executable,
                    str(ROOT / "scripts" / "make_openclash_candidate.py"),
                    str(active_path),
                    str(custom_path),
                    str(output_path),
                ],
                check=True,
                capture_output=True,
                text=True,
            )

            result = yaml.safe_load(output_path.read_text(encoding="utf-8"))
            self.assertEqual(result["rules"][0], "DOMAIN-SUFFIX,steamchina.com,DIRECT")
            self.assertEqual(result["rules"][-1], "MATCH,Proxy")


if __name__ == "__main__":
    unittest.main()
