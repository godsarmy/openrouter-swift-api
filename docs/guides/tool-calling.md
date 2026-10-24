---
type: Guide
title: Tool calling
description: Declare chat tools and decode arguments and encode results with Swift types.
tags: [chat, tools, functions]
---

# Tool calling

With a [configured client](../getting-started/quick-start.md), describe a function
and send it with a chat request:

```swift
let weatherParameters: JSONValue = .object([
  "type": .string("object"),
  "properties": .object([
    "city": .object(["type": .string("string")])
  ]),
  "required": .array([.string("city")])
])

let weatherTool = ChatTool(
  function: .init(
    name: "get_weather",
    description: "Get weather for a city",
    parameters: weatherParameters
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
executing any requested function. The raw `ChatTool`, `ToolCall`, and `ChatMessage`
APIs remain available without the helper below.

## Typed arguments and results

`TypedChatTool<Arguments, Result>` binds a declaration to a `Decodable` argument
type and an `Encodable` result type. Reuse the explicit schema above; the SDK does
not derive a JSON Schema from Swift types.

The following example offers only one tool, explicitly handles every returned
call, and sends one follow-up request. The weather lookup is a **local demo**, not
an actual weather service:

```swift
struct WeatherArguments: Decodable {
  let city: String
}

struct WeatherResult: Encodable {
  let city: String
  let temperatureC: Double
}

enum WeatherExampleError: Error {
  case unsupportedCity
}

func lookupDemoWeather(city: String) throws -> WeatherResult {
  // Replace with your service, authorization checks, and business validation.
  guard city.lowercased() == "london" else {
    throw WeatherExampleError.unsupportedCity
  }
  return WeatherResult(city: city, temperatureC: 12)
}

let weather = TypedChatTool<WeatherArguments, WeatherResult>(
  name: "get_weather",
  description: "Get weather for a city",
  parameters: weatherParameters
)
var history: [ChatMessage] = [.user("What's the weather in London?")]
let toolResponse = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: history,
  tools: [weather.tool],
  toolChoice: .auto
))

if let assistant = toolResponse.choices.first?.message,
   let calls = assistant.toolCalls, !calls.isEmpty {
  history.append(assistant) // Preserve the original message and all its tool calls.
  for call in calls {
    let arguments = try weather.decodeArguments(from: call)
    let result = try lookupDemoWeather(city: arguments.city)
    history.append(try weather.resultMessage(for: call, result: result))
  }
  let finalResponse = try await client.chat.send(.init(
    model: "openai/gpt-4o-mini", messages: history
  ))
  // Consume finalResponse in your app; no automatic execution loop is started.
}
```

If you offer multiple tools, dispatch each call by function name to the correct
helper. Treat arguments as untrusted input: decoding is not authorization or full
JSON Schema validation. Handle failures before sending an incomplete set of tool
results; the example propagates errors instead of retrying or inventing results.

Both helper methods reject non-function calls and mismatched names with
`TypedChatToolError`. `resultMessage` additionally rejects a missing or empty
call ID and preserves the ID verbatim as `tool_call_id`. Argument decoding alone
does not require an ID. JSON decoding and encoding errors propagate unchanged.
Pass a custom `JSONDecoder` or `JSONEncoder` to customize coding strategies.

Results are JSON text inside a `.tool` message. A Swift `String` result is therefore
a JSON-quoted string, not raw text; use `ChatMessage` directly for raw-text results.
The helper handles complete non-streaming calls only, not streaming fragments.
Assistant tool-call messages may contain `content: null`. The SDK represents this
as `Content.null` and preserves it when replaying the original assistant message;
it is distinct from empty text or an empty parts array. An omitted `content` key
is still rejected. When switching exhaustively on `Content`, handle `.null`
alongside `.text` and `.parts`.

See [Responses API](responses.md) for an example
of stateless function-call/output replay and [structured output](structured-output.md)
for constraining a response with JSON Schema.
