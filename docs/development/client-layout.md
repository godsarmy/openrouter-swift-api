---
type: Development Guide
title: Client and model source layout
description: Maintain domain-oriented client and model files without changing public names, encoding, or shared networking behavior.
tags: [development, architecture, client, compatibility]
sources:
  - resource: ../../Sources/OpenRouter/Public/OpenRouterClient.swift
    title: Client storage and initialization
  - resource: ../../Sources/OpenRouter/Public/Client/
    title: Endpoint methods and resource facades
  - resource: ../../Sources/OpenRouter/Public/Models/
    title: Domain models extracted from the legacy bundle
  - resource: ../../Sources/OpenRouter/Internal/Streaming/IncrementalStream.swift
    title: Shared incremental stream runtime
  - resource: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    title: Swift access control
---

# Client and model source layout

`OpenRouterClient` remains one public, `Sendable` value type in the `OpenRouter`
module. Its source is split by responsibility, not into new packages or public
transport abstractions. Directory names organize files; Swift access modifiers
define visibility.

## Responsibilities

| Location | Responsibility |
|---|---|
| `Public/OpenRouterClient.swift` | Stored configuration/transport and public initialization |
| `Public/Client/OpenRouterClient+<Family>.swift` | Endpoint methods, resource factory properties, and corresponding nested resource facades |
| `Public/Configuration.swift` | Still-nested `OpenRouterClient.Configuration` |
| `Public/RequestOptions.swift` | Per-request overrides and `RetryPolicy` |
| `Public/OpenRouterError.swift` | Errors, error conveniences, and error conversion helpers |
| `Public/OpenRouterDebugEvent.swift` | Debug event model |
| `Public/ChatCompletionFallbackPolicy.swift` | Opt-in model fallback policy |
| `Public/ChatCompletionStreamSession.swift` | Public chat stream/metadata result |
| `Internal/Streaming/IncrementalStream.swift` | Shared stream construction, metadata synchronization, URLSession runtime, and delegate |
| `Internal/Streaming/SSEParser.swift` | Existing SSE frame parsing |
| `Internal/Multipart/MultipartEncoding.swift` | Audio/file multipart builders and filename sanitization |
| `Internal/Transport/PathEncoding.swift` | Shared path-segment escaping |
| `Internal/Transport/HTTPTransport.swift` | Existing request construction, authentication, retries, and buffered response handling |

Families include chat, Responses, Messages, embeddings, reranking, audio, files,
batches, images, videos, discovery, generations, keys/auth, BYOK, workspaces,
organization, guardrails, observability, presets, external users, and usage/datasets.
Small related namespaces can share a family file. Do not rebuild one large
miscellaneous client file as coverage grows.

The image request wrapper and stream completion state remain private to the image
family. Shared runtime/delegate implementation remains hidden; moving files did
not redesign cancellation, fallback, event handling, or buffering.

## Adding endpoints

1. Add endpoint methods to the appropriate family extension, or create a coherent
   new family when none fits.
2. Keep the factory property and nested resource type beside their flat methods.
   Preserve both calling styles and nested names such as
   `OpenRouterClient.OrganizationResource`.
3. Keep request/response models in their existing domain model files, including
   those under `Public/Models/`. Do not introduce duplicate model families merely
   because existing and extracted models live in different directories.
4. Use the existing transport and shared helpers; do not duplicate authentication,
   retry, streaming lifecycle, or path-escaping logic in each resource.
5. Add focused offline tests, update the endpoint tracker and usage guide, and
   follow [building and testing](building-and-testing.md).

## Model files

The former `Public/OpenRouterAPIModels.swift` bundle has been removed. Its 142
top-level declarations now live in 18 files under `Public/Models/`:

| Domain | Files |
|---|---|
| Authorization codes and key management | `AuthenticationModels.swift` |
| Chat completion requests/responses and stream chunks | `ChatCompletionModels.swift` |
| Chat messages and multimodal content | `ChatContentModels.swift` |
| Chat tools and structured response formats | `ChatToolModels.swift` |
| Chat reasoning, cache, and search settings | `ChatConfigurationModels.swift` |
| Provider routing and usage details | `ProviderRoutingModels.swift`, `UsageModels.swift` |
| Embeddings and reranking | `EmbeddingModels.swift`, `RerankModels.swift` |
| Audio, uploads, and video | `AudioModels.swift`, `FileModels.swift`, `VideoModels.swift` |
| Responses and Anthropic-compatible Messages | `ResponsesModels.swift`, `MessagesModels.swift` |
| Legacy text completions | `CompletionModels.swift` |
| Discovery, generation metadata, credits, activity, and rankings | `DiscoveryModels.swift`, `AccountActivityModels.swift` |
| Shared JSON values | `JSONValueModels.swift` |

These remain types in the same `OpenRouter` module: callers still write
`import OpenRouter`, `ChatCompletionRequest`, and `JSONValue`, not a new `Models`
namespace. Existing domain files outside this directory remain in place; their
models were not consolidated or redesigned as part of this extraction.

Private codec helpers stay in the same files as their consumers. No model access
modifiers were widened, no new generic PATCH-field abstraction was introduced,
and encoding keys, default values, conformances, and nullable/raw-payload behavior
were preserved. Keep large but cohesive schemas together when splitting would
require unnecessary access changes or obscure custom Codable behavior.

## Access-control rules

Swift permits access to private members from same-type extensions **in the same
file**, not arbitrary files. The client transport, configuration key-copy helper,
shared stream builder/metadata box, path escaping, and cross-family multipart
builders therefore use `internal` access where required. They are not public API;
`HTTPTransport` remains internal.

Keep helpers private when all uses remain in one file, including multipart
filename sanitization. Resource stored-client access and factory placement retain
their existing visibility; avoid blanket `public extension` declarations or
public transport access merely to make an extraction compile.

## Verification for moves

File relocation should not change signatures, default arguments, qualified type
names, protocol conformances, request encoding, or runtime behavior. Separate
behavior fixes and API redesign from mechanical moves.

For a public API baseline, run before and after the move:

```bash
swift package dump-symbol-graph --minimum-access-level public
```

Save the generated graphs outside `.build` between runs. Compare symbol identities,
declarations (including default arguments), access levels, and relationships.
Ignore source locations/documentation positioning and metadata that merely records
an unconstrained extension of the same module's type; do not ignore constraints,
availability, or actual API differences.

The November 3 extraction from `96dfbb5` preserved all **2,734 public symbols** and
their relationships in the Linux toolchain graph. A temporary SwiftSyntax token
audit also matched **462** function, initializer, and variable declarations,
ignoring trivia and leading nonpublic access modifiers while retaining literal
token text. These checks complement tests; they are not an ABI guarantee or an
Apple-platform validation claim. Run the full offline suite, strict formatter,
and documentation checks after reconciling the move.

The later model extraction from `1fbea55` also preserved all **2,734 public
symbols** and their relationships. A separate token audit matched all **142
top-level declarations**, ignoring only imports, comments, and whitespace. It
included access modifiers, coding-key cases, default arguments, and literal text.
This is stronger source-move evidence than compilation alone, but does not replace
the offline serialization tests or establish binary compatibility.
