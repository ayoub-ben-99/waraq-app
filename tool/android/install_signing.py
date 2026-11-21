#!/usr/bin/env python3
"""Installs the release keystore into the generated Android host project.

The workflow exports the whole signing bundle as one base64 secret
(`WARAQ_SIGNING_B64`, base64 of a JSON document) so the repository never holds
key material and only a single secret has to be pasted in the GitHub UI.

Usage: python3 tool/android/install_signing.py
Reads: SIGNING_B64, GITHUB_OUTPUT (optional)
"""

from __future__ import annotations

import base64
import json
import os
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
ANDROID = ROOT / "android"
APP = ANDROID / "app"


def write_output(value: str) -> None:
    target = os.environ.get("GITHUB_OUTPUT")
    if target:
        with open(target, "a", encoding="utf-8") as handle:
            handle.write(f"signed={value}\n")


def main() -> int:
    bundle = os.environ.get("SIGNING_B64", "").strip()
    if not bundle:
        print("WARAQ_SIGNING_B64 is not set: release builds stay debug-signed.")
        write_output("false")
        return 0

    if not APP.is_dir():
        print("android/app is missing: run `flutter create . --platforms=android` first.", file=sys.stderr)
        return 1

    data = json.loads(base64.b64decode(bundle))
    keystore_dir = ANDROID / "keystore"
    keystore_dir.mkdir(parents=True, exist_ok=True)
    keystore = keystore_dir / "release.p12"
    keystore.write_bytes(base64.b64decode(data["keystore_base64"]))

    properties = "\n".join(
        [
            "storeFile=../keystore/release.p12",
            "storeType=PKCS12",
            f"storePassword={data['store_password']}",
            f"keyAlias={data['key_alias']}",
            f"keyPassword={data['key_password']}",
        ]
    )
    (ANDROID / "key.properties").write_text(properties + "\n", encoding="utf-8")

    script = ROOT / "tool" / "android" / "release-signing.gradle.kts"
    (APP / script.name).write_text(script.read_text(encoding="utf-8"), encoding="utf-8")

    build_file = APP / "build.gradle.kts"
    marker = 'apply(from = "release-signing.gradle.kts")'
    source = build_file.read_text(encoding="utf-8")
    if marker not in source:
        build_file.write_text(source.rstrip() + "\n\n" + marker + "\n", encoding="utf-8")

    print("release keystore installed; release builds will use it.")
    write_output("true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
