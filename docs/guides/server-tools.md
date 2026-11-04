---
type: Guide
title: Server-tool catalog
description: Discover server tools, their engines, pricing, schemas, and native model support.
tags: [tools, discovery, catalog]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/Client/OpenRouterClient+Tools.swift
    title: Server-tool client methods
  - resource: ../../Sources/OpenRouter/Public/ServerTools.swift
    title: Catalog response models
---

# Server-tool catalog

Use bearer authentication to discover tools OpenRouter can run for models:

```swift
let catalog = try await client.tools.list()
let page = try await client.tools.list(
  offset: 0, limit: 20, apiFormat: "responses")
let tool = try await client.tools.get(name: "openrouter:web_search")
let models = tool.data.nativeSupport.models
```

The direct methods are `listTools(offset:limit:apiFormat:options:)` and
`getTool(name:options:)`. Both accept request options. Omitting both pagination
arguments requests the full catalog. The server validates offset >= 0 and limit
in 1...100. `totalCount` and `links.next` describe pagination; the SDK does not
fetch subsequent pages automatically. Known API formats are `responses`,
`chat-completions`, and `anthropic-messages`; strings also accept future formats.

List entries contain aliases and their output names, supported API formats,
caller parameters and model input/output JSON Schemas, engine pricing and region
policies, and native endpoint/model counts. Detail responses additionally require
the native model/provider list. Schemas use `[String: JSONValue]` to retain nested
extensions. Status, engine, BYOK, billing-source, region, and format values remain
strings for forward compatibility. Prices remain decimal strings in USD per unit.
Required nullable fields decode null but reject omission; optional output names
may be absent.

Canonical IDs and aliases are escaped as one path segment; empty and dot-segment
names are rejected. The specification describes HTTP 308 redirects for aliases.
Following them depends on the supplied `URLSession` and its redirect policy;
prefer canonical IDs. API and decoding errors use the normal SDK error types.

This catalog does not execute tools or register application functions. For
application-controlled execution, see [tool calling](tool-calling.md).
See [endpoint coverage](../reference/endpoint-coverage.md) for implementation status.

## Contract baseline

These two operations and their referenced schemas were checked against the official
specification retrieved on November 4, 2026 (SHA-256
`08855d8f74f3f44be3b3007576d79aee13faa6ecf6fd5cd790fcd78b51e6a4fb`).
This focused review does not refresh the full endpoint inventory or establish
live account access or cross-SDK field parity. No live inference was performed.
