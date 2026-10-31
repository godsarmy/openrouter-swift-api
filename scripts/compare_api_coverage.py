#!/usr/bin/env python3
"""Compare a saved OpenAPI JSON inventory with Swift and Zig Markdown trackers.

This measures documented endpoint presence, not SDK behavior or field parity.
Paths are compared literally except for placeholder names; server overrides are
not resolved. Only checked Swift rows count; Zig method/path rows count as listed.
"""

import argparse
import hashlib
import json
from pathlib import Path
import re


HTTP_METHODS = frozenset({"GET", "PUT", "POST", "DELETE", "OPTIONS", "HEAD", "PATCH", "TRACE"})


def normalize_path(path):
    """Ignore parameter spelling without changing path case or trailing slashes."""
    return re.sub(r"\{[^}]+\}", "{}", path)


def spec_operations(spec):
    """Extract unique method/path pairs, ignoring path-item metadata."""
    return {
        (method.upper(), normalize_path(path))
        for path, item in spec.get("paths", {}).items()
        if path.startswith("/") and isinstance(item, dict)
        for method in item
        if method.upper() in HTTP_METHODS
    }


def tracker_operations(text, sdk):
    """Read pipe tables, deduplicating summary/detail and normalized routes."""
    if sdk not in {"swift", "zig"}:
        raise ValueError("sdk must be swift or zig")
    operations = set()
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if sdk == "swift":
            if len(cells) < 3 or cells[0] != "[x]":
                continue
            methods, path = cells[1:3]
            verbs = [methods]
        else:
            if len(cells) < 2:
                continue
            methods, path = cells[:2]
            verbs = [verb.strip() for verb in methods.split("/")]
        path = path.strip("`")
        if not path.startswith("/") or not all(verb in HTTP_METHODS for verb in verbs):
            continue
        operations.update((verb, normalize_path(path)) for verb in verbs)
    return operations


def operation_list(operations):
    return [f"{method} {path}" for method, path in sorted(operations)]


def sdk_report(operations, upstream):
    groups = {
        "tracker": operations,
        "implemented": operations & upstream,
        "missing": upstream - operations,
        "retained": operations - upstream,
    }
    return {
        name: {"count": len(routes), "operations": operation_list(routes)}
        for name, routes in groups.items()
    }


def compare(spec, swift, zig, sha256):
    upstream = spec_operations(spec)
    return {
        "spec": {
            "sha256": sha256,
            "path_count": len(spec.get("paths", {})),
            "operation_count": len(upstream),
            "operations": operation_list(upstream),
        },
        "swift": sdk_report(swift, upstream),
        "zig": sdk_report(zig, upstream),
        "comparison": {
            name: {"count": len(routes), "operations": operation_list(routes)}
            for name, routes in {
                "common": swift & zig,
                "swift_only": swift - zig,
                "zig_only": zig - swift,
            }.items()
        },
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--spec", required=True, type=Path, help="Saved OpenAPI JSON (no network access)")
    parser.add_argument("--swift", required=True, type=Path, help="Swift Markdown tracker")
    parser.add_argument("--zig", required=True, type=Path, help="Zig Markdown tracker")
    args = parser.parse_args(argv)
    try:
        with args.spec.open("rb") as source:
            snapshot = source.read()
        spec = json.loads(snapshot.decode("utf-8"))
        trackers = {}
        for sdk in ("swift", "zig"):
            with getattr(args, sdk).open(encoding="utf-8") as source:
                trackers[sdk] = tracker_operations(source.read(), sdk)
        report = compare(spec, trackers["swift"], trackers["zig"], hashlib.sha256(snapshot).hexdigest())
    except (OSError, UnicodeError, ValueError) as error:
        parser.error(str(error))
    print(json.dumps(report, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
