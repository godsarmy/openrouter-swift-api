---
type: Reference
title: Swift and Zig API parity baseline
description: Compare both SDK endpoint trackers against a single dated OpenAPI snapshot and distinguish endpoint coverage from contract parity.
tags: [api, coverage, roadmap, parity]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../PLAN.md
    title: Prioritized cross-language API work
---

# Swift and Zig API parity baseline

The SDKs aim to support the same HTTP API with idiomatic language-specific
interfaces. [PLAN.md](../../PLAN.md) owns priorities; the
[endpoint tracker](endpoint-coverage.md) owns current Swift implementation status.

## Snapshot and method

The official specification was retrieved once on **2026-10-30**:

- SHA-256: `57f7ae9cfd167639fa0ed7692133d489db720a32eaab7d592fc16d65e372143c`.
- Unique method/path operations: **145**.
- Swift tracker baseline: commit `88d01dfd3b5b7bf74c352544000c7eaeb2f5786c`.
- Zig tracker baseline: commit `5ae5da52523c28cc8dcd7cf7cf971d9f32a64a70`,
  `docs/api/coverage.md` in the sibling Zig repository.

Counts expand combined HTTP verbs, deduplicate repeated summary/detail rows, and
normalize path parameter names, so `{id}` and `{workspace_ref}` do not create
false differences. Implemented sets come from tracker tables, not an independent
fresh source audit of every route. BYOK contracts and selected parity findings
were checked against source and the saved specification.

## Before the BYOK milestone

| Tracker inventory | Swift | Zig |
|---|---:|---:|
| Implemented current-snapshot operations | 57 | 137 |
| Missing current-snapshot operations | 88 | 8 |
| Retained implemented operations absent from snapshot | 1 | 13 |
| Total implemented tracker operations | 58 | 150 |

The trackers share **57** implemented operations. Zig has **93** operations absent
from Swift: 80 in the snapshot and 13 retained outside it. Swift alone retains
`POST /completions`. These are baseline figures, not a rolling claim about the
latest source. Adding the five BYOK operations increases Swift snapshot coverage
to 62/145 and reduces the Zig-only difference to 88; it does not add upstream
operations or establish schema parity.

### Shared snapshot gaps

Eight snapshot operations are absent from both baseline implemented inventories:

- `GET` / `POST /private-providers`.
- `GET` / `PATCH` / `DELETE /private-providers/{slug}`.
- `PUT /private-endpoints/{id}/parameters`.
- `GET /vault/interns/{internId}/connections`.
- `POST /credits/coinbase` (excluded by Zig's earlier deprecation audit).

An inventory entry is not a promise of account availability or a recommendation
to restore a deprecated operation. Recheck contract and lifecycle before adding it.

### Retained Zig operations outside the snapshot

The 13 retained operations are two benchmark dataset reads (Artificial Analysis
and Design Arena), intern list/create/get/update/delete, and intern chat, daemon,
daemon signing, invoke, provision, and suspend. Spec absence alone does not prove
server-side removal. Keep these separate from current-spec coverage targets.

## Repeat the comparison

Save one official JSON snapshot, retain its digest with the audit, and run:

```bash
python3 scripts/compare_api_coverage.py \
  --spec /path/to/openapi.json \
  --swift docs/reference/endpoint-coverage.md \
  --zig ../openrouter-zig-sdk/docs/api/coverage.md
```

Use the historical tracker revisions above to reproduce baseline numbers; running
against current trackers intentionally reports subsequent implementation changes.
The original download lives in the review workspace, not in the repository;
refetching the URL may produce different bytes and is a new baseline.

This route comparison does not prove request/response field parity, auth-header
behavior, server overrides, streaming semantics, entitlements, or live availability.
The usual API base is `https://openrouter.ai/api/v1`; alpha Decisions overrides it
with `https://openrouter.ai`. BYOK inherits the usual base and requires management
authentication. Preset semantics, audio encoding, Responses fields, and image
streaming remain separate contract work in the plan.
