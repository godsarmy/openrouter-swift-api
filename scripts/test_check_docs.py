import tempfile
import unittest
from pathlib import Path

from check_docs import frontmatter, local_links, validate


class DocumentationChecksTests(unittest.TestCase):
    def test_frontmatter_mapping(self):
        metadata, body = frontmatter("---\ntype: Guide\n---\n# Example\n")
        self.assertEqual(metadata, {"type": "Guide"})
        self.assertEqual(body, "# Example\n")

    def test_missing_frontmatter(self):
        self.assertEqual(frontmatter("# Example"), (None, "# Example"))

    def test_invalid_frontmatter(self):
        for text in ("---\ntype: [\n---\n", "---\n- item\n---\n", "---\ntype: Guide"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                frontmatter(text)

    def test_link_resolution(self):
        bundle = Path("/example/docs")
        path = bundle / "guides/chat.md"
        links = local_links(
            "[Relative](../index.md#top) [Absolute](/reference/index.md) "
            "[Remote](https://example.com) [Anchor](#heading) "
            "`[Code](missing.md)`\n```md\n[Example](missing.md)\n```\n",
            path,
            bundle,
        )
        self.assertEqual(links, [bundle / "index.md", bundle / "reference/index.md"])

    def test_project_rules(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            docs = root / "docs"
            docs.mkdir()
            for name in ("README.md", "APIs.md", "AGENTS.md", "CHANGELOG.md"):
                (root / name).write_text("# Entry\n", encoding="utf-8")
            (docs / "index.md").write_text(
                '---\nokf_version: "0.2"\n---\n# Bundle\n[Guide](guide.md) - A guide.\n',
                encoding="utf-8",
            )
            guide = docs / "guide.md"
            guide.write_text(
                "---\ntype: Guide\ntitle: Guide\ndescription: A guide.\ntags: [test]\n---\n# Guide\n",
                encoding="utf-8",
            )
            self.assertEqual(validate(root), [])
            guide.write_text("# Missing metadata\n[Broken](missing.md)\n", encoding="utf-8")
            errors = validate(root)
            self.assertTrue(any("nonempty string type" in error for error in errors))
            self.assertTrue(any("broken local link" in error for error in errors))
            (docs / "orphan.md").write_text("# Orphan\n", encoding="utf-8")
            self.assertTrue(any("missing index entry for orphan.md" in error for error in validate(root)))

    def test_reserved_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            nested = root / "docs/nested"
            nested.mkdir(parents=True)
            (nested / "index.md").write_text("---\ntype: Guide\n---\n", encoding="utf-8")
            (nested / "log.md").write_text("# Log\n## Yesterday\n", encoding="utf-8")
            errors = validate(root)
            self.assertTrue(any("nested indexes must not have frontmatter" in error for error in errors))
            self.assertTrue(any("YYYY-MM-DD" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
