"""Synthetic endpoint inventory tests; no network or saved production spec needed."""

import contextlib
import hashlib
import io
import json
from pathlib import Path
import tempfile
import unittest

import compare_api_coverage as coverage


class CoverageTests(unittest.TestCase):
    def test_spec_methods_and_normalization(self):
        spec = {"paths": {
            "/things/{thingId}": {
                **{method.lower(): {} for method in coverage.HTTP_METHODS},
                "parameters": [], "$ref": "ignored", "connect": {},
            },
            "not-a-route": {"get": {}},
        }}
        self.assertEqual(coverage.spec_operations(spec), {
            (method, "/things/{}") for method in coverage.HTTP_METHODS
        })
        self.assertEqual(coverage.normalize_path("/A/{id}/{name}/"), "/A/{}/{}/")

    def test_swift_status_duplicates_and_invalid_cells(self):
        text = """
| Status | Method | Path |
|---|---|---|
| [x] | GET | `/things/{id}` |
| [x] | GET | `/things/{thingId}` | repeated detail |
| [ ] | POST | `/things` |
| [X] | DELETE | `/things/{id}` |
| [x] | CONNECT | `/things` |
| [x] | GET/POST | `/things` |
| [x] | GET | `client.things` |
| [x] | HEAD | `/things` |
| [x] |
"""
        self.assertEqual(coverage.tracker_operations(text, "swift"), {
            ("GET", "/things/{}"), ("HEAD", "/things"),
        })

    def test_zig_combined_verbs_and_duplicates(self):
        text = """
| Method | Path |
|---|---|
| GET / POST / OPTIONS | `/things/{id}` |
| POST | `/things/{name}` |
| HEAD/TRACE | `/things` |
| GET/BOGUS | `/ignored` |
| GET | `not a route` |
| PATCH | `/things` |
"""
        self.assertEqual(coverage.tracker_operations(text, "zig"), {
            ("GET", "/things/{}"), ("POST", "/things/{}"),
            ("OPTIONS", "/things/{}"), ("HEAD", "/things"),
            ("TRACE", "/things"), ("PATCH", "/things"),
        })

    def test_report_sets_include_retained_and_distinguish_methods(self):
        spec = {"paths": {"/things": {"get": {}, "post": {}}}}
        swift = {("GET", "/things"), ("DELETE", "/legacy")}
        zig = {("POST", "/things"), ("DELETE", "/legacy")}
        report = coverage.compare(spec, swift, zig, "digest")
        self.assertEqual(report["spec"]["operation_count"], 2)
        self.assertEqual(report["swift"]["tracker"]["count"], 2)
        self.assertEqual(report["swift"]["implemented"]["operations"], ["GET /things"])
        self.assertEqual(report["swift"]["missing"]["operations"], ["POST /things"])
        self.assertEqual(report["zig"]["retained"]["operations"], ["DELETE /legacy"])
        self.assertEqual(report["comparison"]["common"]["operations"], ["DELETE /legacy"])
        self.assertEqual(report["comparison"]["swift_only"]["operations"], ["GET /things"])
        self.assertEqual(report["comparison"]["zig_only"]["operations"], ["POST /things"])

    def test_cli_utf8_hash_and_deterministic_json(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            snapshot = '{"info":{"title":"Café"},"paths":{"/things":{"get":{}}}}'.encode("utf-8")
            (root / "spec.json").write_bytes(snapshot)
            (root / "swift.md").write_text("| [x] | GET | `/things` | Café |\n", encoding="utf-8")
            (root / "zig.md").write_text("| GET | `/things` |\n", encoding="utf-8")
            args = ["--spec", str(root / "spec.json"), "--swift", str(root / "swift.md"), "--zig", str(root / "zig.md")]
            outputs = []
            for _ in range(2):
                output = io.StringIO()
                with contextlib.redirect_stdout(output):
                    coverage.main(args)
                outputs.append(output.getvalue())
            self.assertEqual(outputs[0], outputs[1])
            report = json.loads(outputs[0])
            self.assertEqual(report["spec"]["sha256"], hashlib.sha256(snapshot).hexdigest())
            self.assertEqual(report["swift"]["implemented"]["count"], 1)


if __name__ == "__main__":
    unittest.main()
