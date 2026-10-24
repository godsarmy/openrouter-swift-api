---
type: Guide
title: Messages API
description: Use Anthropic-compatible messages and streaming events.
tags: [messages, anthropic, streaming]
---

# Messages API

With a [configured client](../getting-started/quick-start.md), use the
Anthropic-compatible Messages API. Set `maxTokens` for compatible providers:

```swift
let message = try await client.messages.create(.init(
  model: "anthropic/claude-sonnet-4",
  messages: [.init(role: .user, content: .text("Hello"))],
  maxTokens: 256
))
for try await event in client.messages.stream(.init(
  model: "anthropic/claude-sonnet-4",
  messages: [.init(role: .user, content: .text("Hello"))], maxTokens: 256
)) {
  if event.type == "content_block_delta" { print(event.delta ?? .null) }
}
```

Unknown Messages blocks and SSE fields remain available through raw payload
values. See [Responses API](responses.md) for the beta Responses event format
and [endpoint coverage](../reference/endpoint-coverage.md) for SDK aliases.
