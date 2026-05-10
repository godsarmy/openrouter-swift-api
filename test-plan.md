# OpenRouter Swift — Test Expansion Plan (from TypeScript SDK tests)

## Goal
Increase parity with `OpenRouterTeam/typescript-sdk` test coverage by adding high-value Swift tests for:
- usage/cost decoding and assertions
- streaming terminal usage semantics
- generation endpoint client behavior
- provider/routing request encoding
- broader error mapping and stream error handling

## Inputs Referenced
- TS tests: `https://github.com/OpenRouterTeam/typescript-sdk/tree/main/tests`
- Current Swift tests:
  - `Tests/OpenRouterTests/OpenRouterModelsTests.swift`
  - `Tests/OpenRouterTests/OpenRouterClientMockedTests.swift`
  - `Tests/OpenRouterTests/OpenRouterTransportTests.swift`
  - `Tests/OpenRouterTests/SSEParserTests.swift`
  - `Tests/OpenRouterTests/OpenRouterIntegrationTests.swift`

---

## Phase 1 (P0) — Must-have parity and regressions

### 1) Usage + Cost model decoding/round-trip
**New file:** `Tests/OpenRouterTests/OpenRouterUsageAndCostTests.swift`

Add tests:
- `testUsageDecodesCostAndIsByok()`
- `testUsageDecodesCostDetails()`
- `testPromptAndCompletionTokenDetailsDecodeExpandedFields()`
- `testUsageEncodingRoundTripPreservesOptionalFields()`

Assertions:
- `usage.cost`, `usage.isByok`, `usage.costDetails.upstreamInferenceCost`
- prompt/completion detail fields (`cached_tokens`, `audio_tokens`, `reasoning_tokens`, etc.)

---

### 2) Streaming terminal usage semantics
**Prefer extending:** `Tests/OpenRouterTests/OpenRouterClientMockedTests.swift`
**Optional split:** `Tests/OpenRouterTests/OpenRouterStreamingTerminalUsageTests.swift`

Add tests:
- `testStreamIncludesTerminalUsageChunkWithCost()`
- `testStreamDoesNotTerminateBeforeDoneWhenFinishReasonArrives()`
- `testStreamDecodesUsageOnlyChunk()`

Fixtures should include SSE sequence:
1. content delta chunk(s)
2. finish_reason chunk (optional)
3. usage chunk (`usage.cost`, token counts)
4. `[DONE]`

Assertions:
- usage chunk is yielded
- stream closes only on `[DONE]`
- no dropped final accounting data

---

### 3) Generation endpoint tests (newly added API)
**New file:** `Tests/OpenRouterTests/OpenRouterGenerationsTests.swift`

Add tests:
- `testGetGenerationBuildsGETWithIdQueryAndHeaders()`
- `testListGenerationContentBuildsGETWithIdQueryAndHeaders()`
- `testGenerationMethodsDecodeJSONValueObject()`
- `testGenerationMethodsMapAPIErrorEnvelope()`

Assertions:
- path/query correctness: `generation?id=...`, `generation/content?id=...`
- auth + optional headers (`HTTP-Referer`, `X-Title`) set
- API error mapping matches existing behavior

---

## Phase 2 (P1) — Reliability and behavior depth

### 4) Routing/provider request encoding
**Extend:** `Tests/OpenRouterTests/OpenRouterModelsTests.swift`

Add tests:
- `testChatCompletionRequestEncodesModelsArray()`
- `testChatCompletionRequestEncodesProviderPreferences()`
- `testChatCompletionRequestEncodesStreamOptionsServiceTierSessionAndParallelToolCalls()`

Assertions:
- JSON keys: `models`, `provider`, `stream_options`, `service_tier`, `session_id`, `parallel_tool_calls`
- nested `provider` keys: `allow_fallbacks`, `order`, `only`, `ignore`, `require_parameters`, `sort`, `zdr`

---

### 5) Stream error chunk decoding
**Extend:** `Tests/OpenRouterTests/OpenRouterModelsTests.swift` and/or mocked client tests

Add tests:
- `testChatCompletionChunkDecodesErrorPayload()`
- `testStreamYieldsChunkWithErrorFieldWithoutDecoderFailure()`

Assertions:
- `ChatCompletionChunk.error.code/message` decode correctly
- chunk metadata fields decode (`object`, `created`, `service_tier`, `system_fingerprint`)

---

### 6) Error mapping matrix expansion
**New file:** `Tests/OpenRouterTests/OpenRouterErrorMappingTests.swift`

Add tests:
- `testDecodeResponseMaps401403404422429500Series()`
- `testDecodeResponseHandlesNonJSONErrorBody()`
- `testDecodeResponseHandlesMalformedEnvelopeGracefully()`

Assertions:
- `OpenRouterError.apiError` population for each status class
- `rawBody` preserved when envelope decode fails

---

## Phase 3 (P2) — Nice-to-have parity enhancements

### 7) Embeddings polymorphism robustness
**Extend:** `Tests/OpenRouterTests/OpenRouterModelsTests.swift`

Add tests for decoding embeddings in multiple shapes where supported by API payload variants (e.g. vector arrays and alternate encoded forms if introduced).

### 8) Live integration assertions for usage/cost (env-gated)
**Extend:** `Tests/OpenRouterTests/OpenRouterIntegrationTests.swift`

Add optional assertions (behind `OPENROUTER_RUN_INTEGRATION=true`):
- non-stream response includes `usage.totalTokens` and optionally `cost`
- stream terminal chunk includes `usage` when API provides it

---

## Execution Order
1. `OpenRouterUsageAndCostTests.swift`
2. Streaming terminal usage tests
3. `OpenRouterGenerationsTests.swift`
4. Routing/provider encoding tests
5. Stream error + metadata decoding tests
6. Error mapping matrix tests
7. Optional integration enhancements

---

## Acceptance Criteria
- All new tests pass with `swift test`
- No existing tests regress
- At least one test guards each newly-added public field/API from recent parity work:
  - `Usage.cost`, `Usage.costDetails`, `Usage.isByok`
  - `ChatCompletionRequest.models/provider/streamOptions/serviceTier/sessionID/parallelToolCalls`
  - `ChatCompletionChunk.usage/error/object/created/serviceTier/systemFingerprint`
  - `OpenRouterClient.getGeneration(id:)`, `listGenerationContent(id:)`
