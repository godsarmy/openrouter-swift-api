---
type: Guide
title: Structured output
description: Request JSON-schema-constrained chat output.
tags: [chat, json-schema, structured-output]
---

# Structured output

With a [configured client](../getting-started/quick-start.md), provide a schema
and select `json_schema` as the response format:

```swift
let jsonSchema = JSONSchemaWrapper(
  name: "summary",
  strict: true,
  schema: .object([
    "type": .string("object"),
    "properties": .object([
      "summary": .object(["type": .string("string")])
    ]),
    "required": .array([.string("summary")])
  ])
)

let structured = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("Summarize this SDK")],
  responseFormat: .init(type: "json_schema", jsonSchema: jsonSchema)
))
```

Schema support depends on the selected model/provider. `JSONValue` is available
for raw or forward-compatible payloads. See [tool calling](tool-calling.md) for
schemas that describe function arguments rather than the final response.
