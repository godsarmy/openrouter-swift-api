---
type: Reference
title: Example CLI
description: Try API features from the terminal with the example executable.
tags: [cli, examples, authentication]
sources:
  - resource: ../../Sources/OpenRouterExamples/main.swift
    title: Example executable
---

# Example CLI

The `OpenRouterExamples` executable target tests API features quickly. Run these
commands from the repository root after [building](../development/building-and-testing.md).
Models below are examples; availability and capabilities depend on your account
and providers. Live requests may incur charges.

## Authentication

Set an API key (placeholder only; never commit a real key):

```bash
export OPENROUTER_API_KEY="<your-key>"
```

For interactive Bash, avoid placing the key in shell history:

```bash
read -rsp "OpenRouter API key: " OPENROUTER_API_KEY
echo
export OPENROUTER_API_KEY
```

## Commands

```bash
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "hello"
swift run OpenRouterExamples chatFallback --model deepseek/deepseek-chat --fallback-models "openai/gpt-4o-mini,anthropic/claude-sonnet-4.5" --prompt "hello"
swift run OpenRouterExamples stream --model openai/gpt-4o-mini --prompt "give me 3 bullets"
swift run OpenRouterExamples generation --generation-id "gen_123"
swift run OpenRouterExamples generationContent --generation-id "gen_123"
swift run OpenRouterExamples models
swift run OpenRouterExamples credits
swift run OpenRouterExamples embed --model text-embedding-3-small --prompt "swift sdk"
swift run OpenRouterExamples complete --model openai/gpt-3.5-turbo-instruct --prompt "hello"
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --system "You are concise" --prompt "hello" --output text
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "summarize" --reasoning-effort high --web-search-context-size medium
swift run OpenRouterExamples chat --model openai/gpt-4o-mini --prompt "summarize" --cache-enabled true --cache-ttl 300
```

`credits` requires a management key. Generation commands require a real generation
ID rather than `gen_123`.

## Options

- `--system <text>` adds a system message before the user prompt.
- `--output json|text` controls output format (default: `json`).
- `--fallback-models <m1,m2,...>` enables fallback routing for `chatFallback`.
- `--generation-id <id>` selects a generation for `generation` and `generationContent`.
- `--reasoning-effort <xhigh|high|medium|low|minimal|none>` sets reasoning effort.
- `--web-search-context-size <low|medium|high>` enables web search context controls.
- `--cache-enabled true|false`, `--cache-ttl <seconds>`, and `--cache-clear true|false` control response caching headers.
- Streaming requests set `stream_options.include_usage=true` so terminal usage chunks can be emitted.

See [chat](../guides/chat.md), [streaming](../guides/streaming.md), and
[resource examples](../guides/resources.md) for SDK equivalents.
