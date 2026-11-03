---
type: Development Guide
title: Client source layout
description: Maintain the SDK's resource-oriented client extensions without changing public names or shared networking behavior.
tags: [development, architecture, client, compatibility]
sources:
  - resource: ../../Sources/OpenRouter/Public/OpenRouterClient.swift
    title: Client storage and initialization
  - resource: ../../Sources/OpenRouter/Public/Client/
    title: Endpoint methods and resource facades
  - resource: ../../Sources/OpenRouter/Internal/Streaming/IncrementalStream.swift
    title: Shared incremental stream runtime
  - resource: https://docs.swift.org/swift-book/documentation/the-swift-programming-language/accesscontrol/
    title: Swift access control
---

# Client source layout

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
3. Keep request/response models in their existing domain model files. This client
   refactor does not reorganize the large legacy model bundle.
4. Use the existing transport and shared helpers; do not duplicate authentication,
   retry, streaming lifecycle, or path-escaping logic in each resource.
5. Add focused offline tests, update the endpoint tracker and usage guide, and
   follow [building and testing](building-and-testing.md).

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
