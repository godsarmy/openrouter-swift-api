---
type: Guide
title: Media APIs
description: Discover image models and work with speech, transcription, video jobs, and downloads.
tags: [audio, images, video, transcription, integration-tests]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
---

# Media APIs

With a [configured client](../getting-started/quick-start.md):

- `client.audio.speech(_:)` creates speech and returns audio `Data`.
- `client.audio.transcribe(_:)` uploads an `AudioTranscriptionFile` and returns typed text, usage, and the raw response payload.
- `client.videos.create(_:)` creates a job; `client.videos.get(jobId:)` polls it.
- `client.videos.models.list()` discovers video-model capabilities.
- `client.videos.content(_:)` downloads a completed video as buffered `Data` and preserves its response `Content-Type` in `VideoContentResponse`.

**Video downloads buffer the complete file in memory.** For large downloads,
prefer the completed job's unsigned URLs.

## Image-model discovery

Use normal API-key authentication to discover image models and their provider
endpoints. Both operations are read-only; they do not generate images:

```swift
let imageModels = try await client.images.models.list()
let imageEndpoints = try await client.images.models.endpoints(
  author: "bytedance-seed", slug: "seedream-4.5"
)
for endpoint in imageEndpoints.endpoints {
  let providerTag = endpoint.providerTag // May be null in the API response.
  let capabilities = endpoint.supportedParameters
  let pricingLines = endpoint.pricing
  // Inspect per-endpoint capabilities and pricing; no generation is started.
}
```

Flat aliases are `client.listImageModels(options:)` and
`client.listImageModelEndpoints(author:slug:options:)`. Both forms accept
`RequestOptions`. There are no pagination or filter parameters in the current
discovery contract. Author and slug are each encoded as a single path segment.

`ImageModelsListResponse.data` contains typed IDs, names, descriptions, integer
creation timestamps, architecture modalities, streaming flags, capability maps,
and a relative `endpoints` URL string. That URL is metadata, not an automatically
followed link; use the endpoint method above rather than appending a URL that
already includes `/api/v1` to the client's base URL.

The model list's `supportedParameters` is a coarse union across endpoints. The
endpoint response is definitive for a particular provider and includes
`providerName`, `providerSlug`, nullable `providerTag`,
`allowedPassthroughParameters`, streaming support, and pricing lines. Each line
has open-string `billable`/`unit`, numeric `costUSD`, and an optional `variant`;
do not assume every endpoint has one flat per-image price.

Capability descriptors remain `[String: JSONValue]`, preserving enum, range,
support-flag, and future descriptor shapes without imposing closed Swift enums.
A descriptor's `type: "boolean"` indicates that a parameter is accepted; do not
infer that the request parameter necessarily takes a Boolean value. Modality and
pricing labels also remain open strings for forward compatibility.

The response envelopes retain `rawPayload`, including unmodeled nested fields.
Encoding uses that payload; changing typed properties alone does not rewrite it.
Inspect these fields as metadata, not a promise of availability or a fixed cost.

**The dedicated image-generation endpoint (`POST /images`) and its native SSE
streaming are not implemented.** `supportsStreaming` describes upstream image
endpoint capability, not an SDK generation method. See [endpoint coverage](../reference/endpoint-coverage.md).

## Live video certification smoke test

The full workflow creates provider work, may take up to 10 minutes, and **incurs
provider cost**. It is opt-in and skipped by default, including during normal
`swift test` runs. Run it only with a supported configured model and an
intentional content download:

```bash
OPENROUTER_RUN_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_INTEGRATION=true \
OPENROUTER_RUN_VIDEO_CONTENT_DOWNLOAD=true \
OPENROUTER_API_KEY="<your-key>" \
OPENROUTER_VIDEO_MODEL="<supported-video-model>" \
swift test --filter OpenRouterIntegrationTests/testIntegrationVideoWorkflow
```

Do not put real secrets in committed scripts or shared shell history. For general
test setup see [building and testing](../development/building-and-testing.md).
For media within chat messages, see [multimodal content](multimodal.md).
