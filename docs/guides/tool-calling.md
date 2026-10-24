---
type: Guide
title: Tool calling
description: Describe function tools in chat requests.
tags: [chat, tools, functions]
---

# Tool calling

With a [configured client](../getting-started/quick-start.md), describe a function
and send it with a chat request:

```swift
let weatherTool = ChatTool(
  function: .init(
    name: "get_weather",
    description: "Get weather for a city",
    parameters: .object([
      "type": .string("object"),
      "properties": .object([
        "city": .object(["type": .string("string")])
      ]),
      "required": .array([.string("city")])
    ])
  )
)

let response = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("What's the weather in London?")],
  tools: [weatherTool],
  toolChoice: .auto
))
```

This declares the tool; your application remains responsible for validating and
executing any requested function. See [Responses API](responses.md) for an example
of stateless function-call/output replay and [structured output](structured-output.md)
for constraining a response with JSON Schema.
