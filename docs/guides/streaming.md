---
type: Guide
title: Streaming
description: Consume chat streams and understand SSE limitations.
tags: [chat, streaming, sse]
sources:
  - resource: ../../Sources/OpenRouter/Public/OpenRouterClient.swift
    title: Streaming client implementation
---

# Streaming

Use `client.chat.stream` to consume chat completions as an asynchronous sequence:

```swift
for try await chunk in client.chat.stream(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("Give me three bullets")]
)) {
  // Inspect each typed chunk in your application.
  print(chunk)
}
```

The [example CLI](../reference/example-cli.md) sets
`stream_options.include_usage=true` for streaming requests so terminal usage
chunks can be emitted.

The SSE parser supports OpenRouter chat streams and basic multiline frame parsing;
the streaming client currently ignores broader SSE metadata. See
[limitations](../reference/limitations.md).

Other streaming protocols have their own event shapes:
[Responses API](responses.md) and [Messages API](messages.md).
