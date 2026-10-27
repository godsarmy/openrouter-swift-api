---
type: Guide
title: Media APIs
description: Discover image models, generate buffered images, and use audio/video APIs.
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

`supportsStreaming` describes upstream image endpoint capability. The SDK
supports buffered generation below, **not native image SSE streaming**. See
[endpoint coverage](../reference/endpoint-coverage.md).

## Buffered image generation

**Image generation starts real provider work and can incur charges.** Normal
tests use mocked responses and never generate images. Submit only intentionally:

```swift
let imageRequest = ImageGenerationRequest(
  model: "bytedance-seed/seedream-4.5",
  prompt: "A red panda astronaut floating in space, studio lighting",
  n: 1,
  outputFormat: "png"
)
// Paid request: uncomment only when intentional.
// let generated = try await client.images.create(
//   imageRequest, options: .init(retries: RetryPolicy.none)
// )
// Decode output explicitly; the SDK does not render or save it:
// let bytes = generated.data.first.flatMap { Data(base64Encoded: $0.b64JSON) }
```

The flat alias is `client.createImage(_:options:)`; both forms accept
`RequestOptions`. `ImageGenerationRequest` requires `model` and a nonempty
`prompt` (validated by the server). It **always encodes `stream: false`** and has
no writable streaming option. Decoding a request with `stream: true` fails rather
than silently enabling SSE. An unexpected SSE response is a decoding failure,
not a successful buffered result.

Optional fields cover `aspectRatio`, `background`, `inputReferences`, `n`,
`outputCompression`, `outputFormat`, `provider`, `quality`, `resolution`, `seed`,
`sessionID`, `size`, `trace`, and `user`; absent fields are omitted. Strings such
as format and quality remain open for future upstream values. No model, seed,
or image-count defaults are invented by the SDK.

- `ImageGenerationReference(url:)` represents an `image_url` input part. Reference
  strings may be HTTP(S) URLs or base64 data URLs; the API accepts up to 16. There
  is no multipart upload or automatic URL fetch by the SDK.
- `ImageGenerationProviderPreferences` exposes `only`, `ignore`, `order`,
  `allowFallbacks`, raw `sort` (string or configuration object), and per-provider
  `options`. Check the definitive endpoint's accepted passthrough keys. The
  server may drop unrecognized options; forwarding them is not a guarantee of
  provider support. `trace` is a raw JSON map for tracing fields.
- `n` is an upper bound from 1 through 10. Providers may return fewer images,
  and single-image providers can reject `n > 1`.
- A tier `size` combines with `aspectRatio`; explicit pixel dimensions are
  authoritative. Conflicting `resolution` or `aspectRatio` can return HTTP 400.
  Transparent backgrounds require an alpha-capable output format. Compression
  and quality support vary by provider; the server validates constraints.
- Reusing `seed` does not guarantee determinism for every provider.

The documented HTTP 200 response is `ImageGenerationResponse`: integer Unix
`created`, a `data` array, optional typed token counts/cost in `usage`, and
`rawPayload`. Each `ImageGenerationImage` requires `b64JSON` and may include
`mediaType`. **The buffered contract returns base64 bytes, not download URLs.**
Do not assume media type is present or output count equals `n`.

PNG/JPEG/WebP are raster outputs; vectorization models may return SVG as
base64-encoded UTF-8 markup. Decode base64 yourself and treat SVG as untrusted
content before rendering. The complete JSON response and base64 strings are
buffered in memory; this is not progressive image delivery.

The response and usage retain authoritative `rawPayload`, preserving unmodeled
image/usage fields. Typed-property edits alone do not rewrite those payloads.
Cost can be null and usage can be absent; detailed provider accounting remains
available in raw usage JSON. API errors, including payment/quota failures (402),
payload limits (413), and upstream failures, use `OpenRouterError.apiError`.
Do not blindly retry paid work after a transport failure: a provider may already
have processed the original request. Retries default to disabled.

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
