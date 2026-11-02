import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("redact_dns", ROOT / "scripts/redact_dns.py")
redactor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(redactor)

class SafetyTests(unittest.TestCase):
    def test_upstream_credentials_never_leave_diagnostics(self):
        source = {"dns": {"upstream_dns": ["https://fake-user:fake-password@dns.example.invalid/private-account?token=FAKE_TOKEN#FAKE_FRAGMENT", "sdns://FAKE_STAMP"]}}
        safe = json.dumps(redactor.redact(source))
        for secret in ["fake-user", "fake-password", "private-account", "FAKE_TOKEN", "FAKE_FRAGMENT", "FAKE_STAMP"]:
            self.assertNotIn(secret, safe)
        self.assertIn("dns.example.invalid", safe)
        self.assertIn("FAKE_TOKEN", json.dumps(source))

    def test_both_cli_audits_redact_before_printing(self):
        with tempfile.TemporaryDirectory() as temp:
            config = Path(temp) / "fake.yaml"
            config.write_text('dns:\n  upstream_dns: ["https://user:FAKE_PASSWORD@dns.example.invalid/FAKE_PATH?key=FAKE_TOKEN"]\n  nameserver: ["https://user:FAKE_PASSWORD@dns.example.invalid/FAKE_PATH?key=FAKE_TOKEN"]\nrules: ["MATCH,DIRECT"]\n', encoding="utf-8")
            for script in ["audit_adguard.py", "audit_openclash.py"]:
                output = subprocess.run([sys.executable, str(ROOT / "scripts" / script), str(config)], capture_output=True, text=True, check=True).stdout
                for secret in ["FAKE_PASSWORD", "FAKE_PATH", "FAKE_TOKEN"]:
                    self.assertNotIn(secret, output)

    def test_uci_failure_restores_rules_and_config(self):
        git = shutil.which("git")
        git_bash = Path(git).parent.parent / "bin/bash.exe" if git else Path("bash.exe")
        bash = str(git_bash) if os.name == "nt" and git_bash.is_file() else shutil.which("bash")
        if not bash:
            self.skipTest("bash is not installed")
        def shellpath(p):
            value = str(p).replace("\\", "/")
            return "/" + value[0].lower() + value[2:] if os.name == "nt" else value
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp); mock = root / "mock"; mock.mkdir()
            def script(name, text):
                p = mock / name; p.write_text("#!/bin/sh\n" + text + "\n", encoding="utf-8", newline="\n"); p.chmod(0o755); return p
            script("uci", 'if [ "$1" = "-q" ]; then echo 0; exit 0; fi\nif [ "$1" = "set" ] && [ "$2" = "openclash.config.enable_custom_clash_rules=1" ]; then exit 9; fi\nexit 0')
            service = script("service", "exit 0")
            config = root / "config"; config.write_text("original config")
            custom = root / "custom"; custom.mkdir()
            rules = custom / "rules"; rules.write_text("original rules")
            candidate = root / "candidate"; candidate.write_text("new rules")
            env = {**os.environ, "PATH": shellpath(mock) + ":/usr/bin:/bin", "I_UNDERSTAND_SAFEOPS_WRITE":"1", "OPENCLASH_CONFIG":shellpath(config), "CUSTOM_DIR":shellpath(custom), "CUSTOM_RULES":shellpath(rules), "BACKUP_ROOT":shellpath(root / "backups"), "OPENCLASH_SERVICE":shellpath(service), "OPENCLASH_CHANGE_FILE":shellpath(root / "change-marker")}
            result = subprocess.run([bash, str(ROOT / "scripts/apply_openclash_custom_rules.sh"), shellpath(candidate), "new rules"], env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 9, result.stderr)
            self.assertEqual(rules.read_text(), "original rules")
            self.assertEqual(config.read_text(), "original config")

if __name__ == "__main__":
    unittest.main()
