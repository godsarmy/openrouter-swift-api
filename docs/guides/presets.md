---
type: Guide
title: Presets
description: Read preset versions and create preset configuration from Chat, Messages, or Responses-shaped request bodies without running inference.
tags: [presets, configuration, management, versions]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/Preset.swift
    title: Preset models
---

# Presets

Use a [configured client](../getting-started/quick-start.md) with a **management
API key**, in an async context. The seven preset operations configure and inspect
saved presets; they are separate from inference calls that consume presets.

## Read presets and versions

```swift
let page = try await client.presets.list(offset: 0, limit: 25)
let totalPresets = page.totalCount
let preset = try await client.presets.get(slug: "production")
if let version = preset.data.designatedVersion {
  let config = version.config
  let versionNumber = version.version
}
let versions = try await client.presets.listVersions(slug: "production", limit: 25)
let historical = try await client.presets.getVersion(slug: "production", version: "1")
```

Preset listing is ordered by most recently updated first; version listing is
ordered by version number ascending (oldest first). Both use manual offset/limit
pagination with `data` and `totalCount`. Omitted pagination uses server defaults
0/50; the server validates offset >= 0 and limit 1–100. There is no workspace
filter parameter on these list operations in the reviewed schema.

Slug and version selectors are nonempty strings, escaped as separate path
segments. The version selector represents a version number, not a version UUID;
returned version numbers are integers. The server validates selector values.

The schema's version object is nullable. A designated version, version-detail
`data`, or an item in a version-list `data` array may therefore be nil. Required
nullable response keys must still be present. Version `config` is a required JSON
object, not an optional blob; `systemPrompt` is nullable. Preset status strings
remain extensible beyond the known `active`, `disabled`, and `archived` values.

List items expose `Preset` metadata directly. Get/write detail items expose it
through `response.data.preset`, alongside `response.data.designatedVersion`;
their JSON encoding remains the API's flat object, without a nested `preset` key.

## Write configuration, not inference

The official operation descriptions explicitly define these POSTs as creating a
preset or a new version of an existing preset:

- `/presets/{slug}/chat/completions`
- `/presets/{slug}/messages`
- `/presets/{slug}/responses`

They **do not run inference**, despite their inference-shaped names and bodies.
Only fields overlapping the preset configuration persist. Non-overlapping fields
such as `messages`, `stream`, and `prompt` are silently ignored by the server.
Do not assume that message history becomes the saved system prompt.

Approve the configuration/version change before running:

```swift
let written = try await client.presets.createFromChatCompletions(
  slug: "production",
  .init(model: "openai/gpt-4o-mini", messages: [.user("Ignored by this configuration route")])
)
let designatedVersion = written.data.designatedVersion
```

The typed helpers accept `ChatCompletionRequest`, `MessagesRequest`, and
`ResponsesRequest` through `createFromChatCompletions`, `createFromMessages`, and
`createFromResponses`. These models retain their normal encoding behavior. The
preset helpers do not force `stream = false`, strip input fields, or invoke SSE
parsers. A supplied streaming flag does not turn a preset write into inference.
Success is HTTP **200**, including when a preset is first created, and returns
preset metadata with the designated version inline, not generated text.

Each write also has an explicit `body: [String: JSONValue]` overload. Use it when
the API-shaped source body needs fields the existing typed request models do not
expose. It sends the supplied object directly, without wrapping or rewriting it.
It does not promise that unknown fields will be persisted: the server chooses
which overlapping configuration fields to save. The source request schemas still
define their required inputs; the raw overload is not a way to bypass validation.

Read config objects preserve arbitrary nested JSON values; they are not a closed
Swift schema for every possible provider setting. Configs, prompt text, and
caller-provided request data may contain sensitive application information. Avoid
printing or persisting them unintentionally.

## Aliases and operational limits

Flat aliases are `listPresets`, `getPreset`, `listPresetVersions`,
`getPresetVersion`, `createPresetsChatCompletions`, `createPresetsMessages`, and
`createPresetsResponses`. Every method accepts per-request `RequestOptions`.

Normal typed API errors expose authentication, permission, validation, missing
preset/version, conflict, and server failures. Read operations also document
HTTP 503. Retries default to disabled. Repeating a write may create another
version: do not blindly retry an ambiguous failure, and do not assume write
idempotency. The SDK does not automatically execute, promote, delete, or roll
back a preset after these operations.

The configuration-only conclusion comes from the verified October 31 OpenAPI
snapshot. Zig's coverage labels these POSTs as inference; that wording is not the
contract used by Swift. No live preset mutations or inference were used for
validation. Account access and server-side configuration selection are not
established by offline tests.

See [endpoint coverage](../reference/endpoint-coverage.md) and the
[parity plan](../../PLAN.md) for remaining work.
