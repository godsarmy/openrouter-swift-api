---
type: Guide
title: Chat
description: Send chat requests and discover optional request features.
tags: [chat, routing, caching, reasoning]
---

# Chat

Create a client as shown in the [quick start](../getting-started/quick-start.md),
then call the resource namespace:

```swift
let response = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("What's the weather in London?")]
))
```

The SDK exposes optional reasoning, web search, response caching, provider routing,
and client-side fallback helpers. The [example CLI](../reference/example-cli.md)
includes commands for reasoning effort, search context, caching, system messages,
and fallback model selection. These are features of existing endpoints, not
separate API endpoints, and support varies by model/provider.

See [streaming](streaming.md), [tool calling](tool-calling.md),
[structured output](structured-output.md), and [multimodal content](multimodal.md)
for related request patterns. Flat client methods remain available alongside
resource namespaces; see [endpoint coverage](../reference/endpoint-coverage.md).
