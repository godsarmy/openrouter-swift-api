---
type: Development Guide
title: Building and testing
description: Build, run offline tests, check formatting, and opt into live tests safely.
tags: [development, tests, ci, formatting]
sources:
  - resource: ../../.github/workflows/ci.yml
    title: CI workflow
  - resource: ../../Tests/OpenRouterTests/OpenRouterIntegrationTests.swift
    title: Live integration test gates
---

# Building and testing

Run from the repository root with Swift 6.0 or newer:

```bash
swift build --configuration debug
swift test
```

CI builds and tests on Linux and macOS using Swift 6.0. A normal `swift test` run
does not need an API key; live integration tests are skipped unless explicitly
enabled. Use [WSL development](../getting-started/wsl-development.md) for Linux setup.

## Formatting

The formatting CI job uses Swift 6.2.0:

```bash
swift format lint --strict --parallel --recursive Package.swift Sources Tests
```

## Live integration tests

Live tests send real API requests and may incur provider charges. Only enable
them intentionally. Set `OPENROUTER_API_KEY` securely, then opt into the non-video
integration tests:

```bash
OPENROUTER_RUN_INTEGRATION=true swift test --filter OpenRouterIntegrationTests
```

Video has additional independent gates and is still skipped by that command.
See [media APIs](../guides/media.md) before enabling a paid video workflow or
content download. Never commit credentials or print secrets in test logs.

For documentation-only edits, run the separate
[documentation checks](documentation.md#validation) as well.
