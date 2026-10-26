# Security Policy

## Reporting

Do not open a public issue containing:

- subscription URLs or proxy credentials
- router, AdGuard, or Mihomo passwords
- API secrets, private keys, or password hashes
- raw router configurations
- DNS query logs containing private domains

Report security issues privately through GitHub's security advisory feature for
this repository. Include a minimal, redacted reproduction.

## Safety model

This project is designed for read-first operations:

1. Inspect the active configuration and service topology.
2. Generate a candidate file instead of editing the live configuration.
3. Validate the candidate with the application's own configuration checker.
4. Back up the active files before applying changes.
5. Restart only the affected service.
6. Verify DNS answers, actual connection chains, and rollback readiness.

The scripts do not intentionally persist credentials. Temporary SSH keys and
raw captures should be removed after the task unless the owner explicitly asks
to retain them.

## Supported versions

Security fixes are applied to the latest `main` branch and the latest release.
