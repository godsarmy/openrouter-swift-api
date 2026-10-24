---
type: Development Guide
title: Documentation maintenance
description: Maintain the OKF bundle and run documentation checks.
tags: [documentation, okf, development]
sources:
  - resource: https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md
    title: Open Knowledge Format v0.2 specification
---

# Documentation maintenance

`docs/` is the self-contained OKF v0.2 documentation bundle. The repository root
is not the bundle: `README.md`, `AGENTS.md`, `APIs.md`, and `CHANGELOG.md` retain
their GitHub and repository workflow roles outside it.

## Concept conventions

- Write one coherent concept per UTF-8 Markdown file using a lowercase kebab-case filename.
- Begin every concept with parseable YAML frontmatter and a nonempty string `type`.
- Include `title`, a one-sentence `description`, and a list of `tags`.
- Use project types `Guide`, `Reference`, and `Development Guide`. These are local conventions, not an OKF registry.
- Link to prerequisites and related concepts with standard relative Markdown links, which work on GitHub and in OKF consumers.
- Keep one canonical location for each example or reference; use links rather than copying full sections.
- Check API claims against source code, tests, and upstream reference material. Add `sources` metadata when useful.

`index.md` and `log.md` are reserved filenames, not concepts. Each directory has
an index of links with short descriptions. Indexes have no frontmatter except
the bundle-root index, which declares `okf_version: "0.2"`. The log uses newest-first
`YYYY-MM-DD` headings. It tracks documentation changes, not package releases.

## Provenance and trust

Use optional OKF metadata honestly. `generated` identifies the actual producer
and change time; `verified` records a real source check, not simply successful
Markdown linting. Use `human:<id>` only for actual human authorship or review.
Do not infer human verification from an agent's edits or claim API correctness
from a link check. No verification claim is required for conformance.

The bundle references source code and upstream APIs rather than duplicating
OpenAPI schemas. Sources outside `docs/` remain repository or external references;
all guide navigation and usage content lives inside the bundle.

## Validation

Python tooling is separate from the Swift package. From the repository root:

```bash
sudo apt install -y python3-venv
python3 -m venv .venv-docs
.venv-docs/bin/python -m pip install -r scripts/requirements-docs.txt
.venv-docs/bin/python scripts/check_docs.py
.venv-docs/bin/python -m unittest discover -s scripts -p 'test_*.py'
```

The checker validates YAML, required and project-recommended metadata, reserved
files, local Markdown link destinations, and index coverage. It also checks links
in the root entry points. It does not fetch remote URLs, type-check code examples,
or verify Markdown heading anchors. Accidental broken local links are rejected
as a project quality rule even though OKF permits unresolved links.

When adding or moving a page, update its directory index, inbound links, and
[documentation log](../log.md). Keep essential roadmap status in the root
[README](../../README.md); keep release history in [CHANGELOG.md](../../CHANGELOG.md).
