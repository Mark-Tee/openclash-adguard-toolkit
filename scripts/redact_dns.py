"""Redact DNS endpoint credentials before diagnostics leave the process."""
import re
from urllib.parse import urlsplit, urlunsplit

URL = re.compile(r"(?i)\b(?:https?|tls|quic|h3|tcp|udp|sdns)://[^\s\"<>]+")

def endpoint(match):
    value = match.group(0)
    try:
        parsed = urlsplit(value)
        if parsed.scheme.lower() == "sdns":
            return "sdns://***"
        host = parsed.hostname
        if not host:
            return "<redacted-url>"
        if ":" in host:
            host = "[" + host + "]"
        if parsed.port:
            host += ":" + str(parsed.port)
        return urlunsplit((parsed.scheme, host, "/***" if parsed.path not in ("", "/") else parsed.path,
                          "***" if parsed.query else "", "***" if parsed.fragment else ""))
    except ValueError:
        return "<redacted-url>"

def redact(value):
    if isinstance(value, dict):
        return {key: redact(item) for key, item in value.items()}
    if isinstance(value, list):
        return [redact(item) for item in value]
    if isinstance(value, str):
        return URL.sub(endpoint, value)
    return value
