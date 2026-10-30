# OpenRouter Swift

Swift Package SDK for the OpenRouter API, inspired by
[`revrost/go-openrouter`](https://github.com/revrost/go-openrouter).

Requires **Swift 6.0+**. Supports Linux development and declares iOS 15/macOS 12
minimums. See [installation](docs/getting-started/installation.md) to add the
`OpenRouter` product to your application.

## Quick start

```swift
import OpenRouter

let client = OpenRouterClient(apiKey: "<OPENROUTER_API_KEY>")
let response = try await client.chat.send(.init(
  model: "openai/gpt-4o-mini",
  messages: [.user("Hello")]
))
```

Run requests in an async context. Load real credentials securely; never commit
API keys. Live requests may incur provider charges.

## Documentation

The [documentation index](docs/index.md) is an **Open Knowledge Format (OKF) v0.2**
bundle: linked Markdown concepts with YAML metadata, readable on GitHub without
special tooling.

- [Getting started](docs/getting-started/index.md): installation, first request, and WSL setup.
- [SDK guides](docs/guides/index.md): chat, streaming, tools, structured output, multimodal, Responses, Messages, and media APIs.
- [Example CLI](docs/reference/example-cli.md): run API examples from the terminal.
- [Endpoint coverage](docs/reference/endpoint-coverage.md): implemented APIs and remaining endpoint work.
- [Current limitations](docs/reference/limitations.md): beta behavior and compatibility constraints.
- [Development](docs/development/index.md): building, testing, formatting, and documentation maintenance.
- [Changelog](CHANGELOG.md): package release history.
- [Versioning policy](docs/development/versioning.md): compatibility and release conventions.

## Development

```bash
swift build
swift test
```

Normal tests do not require an API key. Live integration tests are opt-in and
can incur charges; see [building and testing](docs/development/building-and-testing.md).

## Roadmap

Typed chat argument/result helpers are available; see
[tool calling](docs/guides/tool-calling.md) and
[streaming tool-call assembly](docs/guides/streaming.md#streaming-tool-calls).
Raw chat/tool APIs remain canonical,
and applications retain control of execution.

Endpoint coverage and deferred namespaces are tracked in
[Endpoint coverage](docs/reference/endpoint-coverage.md). The prioritized
[Swift / Zig API parity TODOs](PLAN.md) track the shared API goal and source-review
baseline. **Next: BYOK management**, followed by guardrails and observability
destinations; broader pagination helpers are secondary to closing API gaps.

Remaining follow-ups:

- Track additional beta Responses event fields as OpenRouter confirms them;
  provider-specific fields may still require raw payload access.
- Workspace and organization member async pagination helpers are available; see
  [member pagination](docs/guides/resources.md#member-pagination). Helpers for other
  offset-based resources and cursor-based files/batches remain deferred.
- Organization member listing is supported with management keys.
- Workspace budget list/get/upsert/delete is supported with management keys.
- Workspace member listing is supported with management keys and optional async pagination.
- Other organization APIs, guardrails, BYOK, and
  other unimplemented namespaces remain deferred; see the tracker for details.
