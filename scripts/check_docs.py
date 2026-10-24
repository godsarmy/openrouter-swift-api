"""Validate this project's OKF bundle and local documentation links.

This checks the project's stricter authoring conventions, not every possible
OKF document. Remote URLs and heading anchors are deliberately not checked.
"""

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

import yaml


ROOT = Path(__file__).resolve().parents[1]
FENCE = re.compile(r"^```[^\n]*\n.*?^```[^\n]*$", re.MULTILINE | re.DOTALL)
LINK = re.compile(r"\[[^\]\n]*\]\(<?([^\s)>]+)>?(?:\s+\"[^\"]*\")?\)")


def frontmatter(text):
    """Return metadata and body, rejecting malformed or non-mapping YAML."""
    lines = text.splitlines(keepends=True)
    if not lines or lines[0].strip() != "---":
        return None, text
    end = next((i for i in range(1, len(lines)) if lines[i].strip() == "---"), None)
    if end is None:
        raise ValueError("unclosed YAML frontmatter")
    try:
        metadata = yaml.safe_load("".join(lines[1:end]))
    except yaml.YAMLError as error:
        raise ValueError(f"invalid YAML: {error}") from error
    if not isinstance(metadata, dict):
        raise ValueError("frontmatter must be a YAML mapping")
    return metadata, "".join(lines[end + 1:])


def local_links(body, path, bundle):
    """Resolve inline local Markdown destinations, excluding code examples."""
    prose = FENCE.sub("", body)
    prose = re.sub(r"`[^`\n]*`", "", prose)
    targets = []
    for match in LINK.finditer(prose):
        url = urlsplit(match.group(1))
        if url.scheme or url.netloc or not url.path:
            continue
        value = unquote(url.path)
        # OKF absolute paths are relative to the bundle root, not the repo.
        target = bundle / value.lstrip("/") if value.startswith("/") else path.parent / value
        targets.append(target.resolve())
    return targets


def validate(root):
    root = root.resolve()
    bundle = root / "docs"
    errors = []
    documents = sorted(bundle.rglob("*.md"))
    if not documents:
        return ["docs/: no Markdown documents found"]
    entries = [root / name for name in ("README.md", "APIs.md", "AGENTS.md", "CHANGELOG.md")]
    for path in documents + entries:
        label = str(path.relative_to(root))
        try:
            metadata, body = frontmatter(path.read_text(encoding="utf-8"))
            if path in documents:
                if path.name == "index.md":
                    if path == bundle / "index.md":
                        if metadata != {"okf_version": "0.2"}:
                            errors.append(f"{label}: root index must declare only okf_version: '0.2'")
                    elif metadata is not None:
                        errors.append(f"{label}: nested indexes must not have frontmatter")
                    linked = set(local_links(body, path, bundle))
                    for child in sorted(path.parent.iterdir()):
                        if child == path or not (child.is_dir() or child.suffix == ".md"):
                            continue
                        if child.resolve() not in linked and (child / "index.md").resolve() not in linked:
                            errors.append(f"{label}: missing index entry for {child.name}")
                elif path.name == "log.md":
                    if metadata is not None:
                        errors.append(f"{label}: logs must not have frontmatter")
                    dates = re.findall(r"^## (.+)$", body, re.MULTILINE)
                    if not dates or any(not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date) for date in dates):
                        errors.append(f"{label}: log requires YYYY-MM-DD headings")
                    elif dates != sorted(dates, reverse=True):
                        errors.append(f"{label}: log dates must be newest first")
                else:
                    for key in ("type", "title", "description"):
                        if not metadata or not isinstance(metadata.get(key), str) or not metadata[key].strip():
                            errors.append(f"{label}: requires nonempty string {key}")
                    tags = metadata.get("tags") if metadata else None
                    if not isinstance(tags, list) or not tags or any(not isinstance(tag, str) or not tag.strip() for tag in tags):
                        errors.append(f"{label}: requires a nonempty list of string tags")
                if not (path.parent / "index.md").is_file():
                    errors.append(f"{label}: directory has no index.md")
            for target in local_links(body, path, bundle):
                if not target.exists():
                    errors.append(f"{label}: broken local link to {target}")
        except (OSError, UnicodeError, ValueError) as error:
            errors.append(f"{label}: {error}")
    return errors


if __name__ == "__main__":
    issues = validate(ROOT)
    if issues:
        print("\n".join(issues), file=sys.stderr)
        sys.exit(1)
    print("Documentation checks passed (OKF metadata, indexes, logs, and local links).")
