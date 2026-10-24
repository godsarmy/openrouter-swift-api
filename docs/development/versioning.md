---
type: Reference
title: Versioning
description: Understand source compatibility and release policy.
tags: [versioning, compatibility, releases]
---

# Versioning

Before `1.0`, minor versions may add APIs and patch versions are reserved for
compatible fixes. After `1.0`, the package follows semantic versioning: breaking
source changes require a major version, additive APIs use minor versions, and
bug fixes use patch versions.

## API review notes from v0.2.0

- Current public APIs are expected to remain source-compatible through `0.x` where practical.
- Flat client methods remain available alongside resource namespaces for compatibility.
- `JSONValue` remains the escape hatch for raw/forward-compatible payloads.
- Broader beta/resource coverage remains intentionally incremental.

Package releases are recorded in the [changelog](../../CHANGELOG.md).
Documentation updates are recorded separately in the [bundle log](../log.md).
Consult [endpoint coverage](../reference/endpoint-coverage.md) and
[limitations](../reference/limitations.md) for the current feature status rather
than treating historical release exclusions as current limitations.
