---
type: Guide
title: Resource examples
description: Access generation metadata, discovery, keys, activity, and reranking.
tags: [resources, models, keys, authentication, rerank]
---

# Resource examples

These snippets assume a [configured client](../getting-started/quick-start.md)
and an async context. Check [endpoint coverage](../reference/endpoint-coverage.md)
for aliases, supported filters, and authentication requirements.

## Generation metadata

```swift
let generation = try await client.getGeneration(id: "gen_123")
let generationContent = try await client.listGenerationContent(id: "gen_123")

// Raw fallback JSON helpers.
let generationRaw = try await client.getGenerationRaw(id: "gen_123")
let generationContentRaw = try await client.listGenerationContentRaw(id: "gen_123")
```

## Discovery, credits, and activity

```swift
let models = try await client.models.list()
let userModels = try await client.models.listUser(offset: 0, limit: 25)
let credits = try await client.credits.get()
let activity = try await client.activity.get(date: "2026-08-10", groupBy: "workspace")
let rankings = try await client.datasets.rankingsDaily(period: "week", modality: "text")
let providers = try await client.providers.list()
let endpoints = try await client.endpoints.list(author: "openai", slug: "gpt-4o-mini")
let zdrEndpoints = try await client.endpoints.listZDR()
```

Credits and activity require a management API key.

## Key management and authorization codes

Current-key metadata accepts an ordinary bearer key. Management operations and
authorization-code creation require a management key. **Creating/updating keys
changes account state. Deleting a key is permanent.**

```swift
let currentKey = try await client.keys.current()
let managedKeys = try await client.keys.list(includeDisabled: false, offset: 0)
let managedKey = try await client.keys.get(hash: "hash_example_metadata_only")
let disabledKey = try await client.keys.update(
  hash: "hash_example_metadata_only", .init(disabled: true)
)
// Destructive and permanent: only run after confirming the target key.
// let confirmation = try await client.keys.delete(hash: "hash_example_metadata_only")
let createdKey = try await client.keys.create(.init(name: "Service integration"))
// `createdKey.key` is returned once; store it securely without logging or printing it.
// Authorization codes require a management key. Prefer S256 PKCE; codes are short-lived and single-use.
let authCodeRequest = CreateAuthKeysCodeRequest(
  callbackURL: "https://example.com/openrouter/callback",
  codeChallenge: "base64url-sha256-challenge",
  codeChallengeMethod: "S256"
)
// Do not print or persist the returned authorization code.
// let authCode = try await client.auth.keys.createCode(authCodeRequest)
```

Authorization-code exchange is not yet implemented; see
[endpoint coverage](../reference/endpoint-coverage.md).

## Reranking

```swift
let reranked = try await client.rerank.create(.init(
  model: "cohere/rerank-v3.5", query: "Swift concurrency",
  documents: [.text("Actors protect mutable state."), .object(.init(text: "Structured concurrency guide"))],
  topN: 2
))
```

For embeddings and legacy completions, see the [example CLI](../reference/example-cli.md).
