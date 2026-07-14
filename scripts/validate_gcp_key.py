#!/usr/bin/env python3
"""Validate a Google Cloud service account JSON key file.

Usage:
  python scripts/validate_gcp_key.py [path/to/gcp-sa-key.json]

This script does lightweight validation and reports common issues without
printing the private key contents.
"""
import json
import sys
from pathlib import Path


def validate(path: Path):
    if not path.exists():
        print(f"MISSING: {path}")
        return 2
    try:
        data = json.loads(path.read_text())
    except Exception as e:
        print(f"INVALID_JSON: {e}")
        return 2

    required = ["type", "client_email", "private_key_id", "private_key"]
    missing = [k for k in required if k not in data]
    if missing:
        print(f"MISSING_FIELDS: {missing}")
        return 2

    pk = data.get("private_key", "")
    if not pk.startswith("-----BEGIN PRIVATE KEY-----"):
        print("BAD_PRIVATE_KEY_FORMAT: private_key should start with BEGIN PRIVATE KEY")
        return 2

    lines = pk.count("\n")
    print("OK: key file looks well-formed")
    print("type:", data.get("type"))
    print("client_email:", data.get("client_email"))
    print("private_key_id:", data.get("private_key_id"))
    print("private_key_lines:", lines)
    return 0


def main():
    p = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("gcp-sa-key.json")
    rc = validate(p)
    sys.exit(rc)


if __name__ == "__main__":
    main()
