---
type: Guide
title: Quick start
description: Create a client and send a first chat request.
tags: [swift, chat, authentication]
---

# Quick start

After [installing the SDK](installation.md), import the library and create a client:

```swift
import OpenRouter

let client = OpenRouterClient(apiKey: "<OPENROUTER_API_KEY>")
```

In an async context, send a request:

```swift
let response = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("Hello")]
))
```

Load real credentials from your environment or secure storage rather than
hardcoding them. Never commit keys. Live requests may incur provider charges,
and model availability depends on your account and provider configuration.

To try a request without writing an application, use the
[example CLI](../reference/example-cli.md). Continue with
[chat](../guides/chat.md) or [streaming](../guides/streaming.md).
