# OpenRouter Swift

Swift Package SDK for OpenRouter API, inspired by [`revrost/go-openrouter`](https://github.com/revrost/go-openrouter).

## Status

Early implementation in progress.

Track progress in:

- `PLAN.md`
- `FEATURE_PARITY.md`
- `COMPATIBILITY.md`

## Quick Start

```swift
import OpenRouter

let client = OpenRouterClient(apiKey: "<OPENROUTER_API_KEY>")
```

## Example CLI

The `OpenRouterExamples` executable target can be used to test API features quickly.

Set API key:

```bash
export OPENROUTER_API_KEY="<your-key>"
```

Run commands:

```bash
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "hello"
swift run OpenRouterExamples stream --model openai/gpt-4o-mini --prompt "give me 3 bullets"
swift run OpenRouterExamples embed --model text-embedding-3-small --prompt "swift sdk"
swift run OpenRouterExamples complete --model openai/gpt-3.5-turbo-instruct --prompt "hello"
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --system "You are concise" --prompt "hello" --output text
```

Options:

- `--system <text>` adds a system message before the user prompt
- `--output json|text` controls output format (default: `json`)
