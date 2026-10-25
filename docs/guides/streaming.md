---
type: Guide
title: Streaming
description: Consume chat streams and assemble complete streamed function calls.
tags: [chat, streaming, sse]
sources:
  - resource: ../../Sources/OpenRouter/Public/OpenRouterClient.swift
    title: Streaming client implementation
  - resource: ../../Sources/OpenRouter/Public/ChatToolCallAccumulator.swift
    title: Streamed tool-call assembly
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

## Streaming tool calls

Chat chunks expose `choice.delta?.toolCalls` as `[ToolCallDelta]`. Each delta
identifies a tool by its index within a choice; `function.arguments` contains a
fragment, not necessarily valid JSON. Do not execute it as it arrives.

Feed all chunks into `ChatToolCallAccumulator`, then call `finish()` **only after
the stream ends normally**. The returned dictionary is keyed by choice index;
each array is ordered by tool index. For example, this single-choice echo tool
uses the [typed helper](tool-calling.md) after assembly:

```swift
struct EchoArguments: Decodable {
  let message: String
}

let echo = TypedChatTool<EchoArguments, String>(
  name: "echo",
  description: "Repeat a message",
  parameters: .object([
    "type": .string("object"),
    "properties": .object([
      "message": .object(["type": .string("string")])
    ]),
    "required": .array([.string("message")])
  ])
)
let initialHistory: [ChatMessage] = [.user("Use echo to repeat hello")]
var accumulator = ChatToolCallAccumulator()
var assistantText = ""
for try await chunk in client.chat.stream(.init(
  model: "openai/gpt-4o-mini",
  messages: initialHistory,
  tools: [echo.tool],
  toolChoice: .auto
)) {
  try accumulator.append(chunk)
  for choice in chunk.choices where choice.index == 0 {
    assistantText += choice.delta?.content ?? ""
  }
}
// If iteration throws or is cancelled, propagate the error; do not call finish().
let completed = try accumulator.finish()
if let calls = completed[0], !calls.isEmpty {
  let assistant = ChatMessage(
    role: .assistant,
    content: assistantText.isEmpty ? .null : .text(assistantText),
    toolCalls: calls
  )
  var history = initialHistory + [assistant]
  for call in calls {
    let arguments = try echo.decodeArguments(from: call)
    // This local echo is application-controlled execution, not an SDK handler.
    history.append(try echo.resultMessage(for: call, result: arguments.message))
  }
  let finalResponse = try await client.chat.send(.init(
    model: "openai/gpt-4o-mini", messages: history
  ))
  // Consume finalResponse in your app.
}
```

For multiple tools, dispatch by name to the appropriate helper. For multiple
choices, select a choice explicitly; do not combine alternative choices into one
conversation. The accumulator assembles tool calls only: retain text and other
metadata needed by your application separately.

### Completion and failure rules

- Every choice with tool data must receive `finish_reason: "tool_calls"`.
  A terminal reason without calls, or a different terminal reason after partial
  tool data, is rejected. A text-only stream returns an empty dictionary.
- Tool deltas require nonnegative choice and tool indexes. Completed calls require
  nonempty IDs and names, function type, and arguments that form a JSON object.
  This checks JSON syntax/shape, not your schema or authorization rules.
- Arguments are concatenated in arrival order. IDs, names, and types are stable
  metadata: identical repeats are allowed, conflicts are rejected. An omitted
  type defaults to `"function"`; names and IDs are not concatenated.
- Later usage-only chunks are allowed. A top-level stream error, conflicting
  completion, or late tool delta rejects the accumulation even after a finish
  marker. Continue consuming the stream rather than executing at the marker.
- Failed or finalized accumulators cannot be reused. Create a new one for a new
  request. No partial results are exposed after an error.

The accumulator cannot observe SSE `[DONE]` itself. The `tool_calls` finish reason
is its completion gate; it does not prove that the transport delivered `[DONE]`.
A normal EOF without the required finish reason rejects partial tool calls.
Transport failures and cancellation remain the caller's responsibility: never
finalize after catching one, or after breaking out of iteration early. Assembly
buffers argument strings in memory; it does not execute tools or start a loop.

The SSE parser supports OpenRouter chat streams and basic multiline frame parsing;
the streaming client currently ignores broader SSE metadata. See
[limitations](../reference/limitations.md).

Other streaming protocols have their own event shapes:
[Responses API](responses.md) and [Messages API](messages.md).
