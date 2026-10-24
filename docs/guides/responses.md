---
type: Guide
title: Responses API
description: Use beta Responses creation, streaming, and stateless tool replay.
tags: [responses, beta, streaming, tools, reasoning]
---

# Responses API

The Responses API remains **beta**. With a
[configured client](../getting-started/quick-start.md), create a response:

```swift
let response = try await client.responses.create(.init(
  model: "openai/o4-mini",
  input: .text("hello")
))
```

## Streaming

SSE events retain their raw payload for forward compatibility:

```swift
for try await event in client.responses.stream(.init(model: "openai/o4-mini", input: .text("hello"))) {
  if event.type == "response.output_text.delta" || event.type == "response.content_part.delta" {
    print(event.delta ?? "", terminator: "")
  }
  // `response.function_call_arguments.delta` is exposed through `event.delta` too.
}
```

Provider-specific beta fields may still require `rawPayload`.

## Function calls and stateless replay

Reasoning-capable models can preserve reasoning context with
`include: ["reasoning.encrypted_content"]` and `context: "all_turns"`:

```swift
let tool = ResponsesFunctionTool(name: "get_weather", parameters: .object(["type": .string("object")]))
let userMessage = ResponsesInputMessage(role: "user", content: [.init(text: "Weather in Paris?")])
let first = try await client.responses.create(.init(
  model: "openai/o4-mini", input: .messages([userMessage]),
  reasoning: .init(context: "all_turns"), tools: [tool], include: ["reasoning.encrypted_content"]
))
if let call = first.output.compactMap(\.functionCall).first {
  let replayItems: [ResponsesInputItem] =
    [.message(userMessage)]
    + first.output.compactMap(\.reasoningItem).map(ResponsesInputItem.reasoning)
    + [.functionCall(call), .functionCallOutput(.init(callID: call.callID, output: .text("Sunny")))]
  let followUp = try await client.responses.create(.init(
    model: "openai/o4-mini",
    input: .items(replayItems)
  ))
}
```

The weather result above is illustrative; a real application must validate and
execute the requested tool. See [chat tool calling](tool-calling.md) for the chat
format and [limitations](../reference/limitations.md) for deferred beta work.
