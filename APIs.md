# OpenRouter API Implementation Tracker

This file tracks which OpenRouter API endpoints are implemented by this Swift SDK.

Source reviewed:

- API reference overview: <https://openrouter.ai/docs/api/reference/overview>
- OpenAPI spec: <https://openrouter.ai/openapi.json>
- Audio API announcement: <https://openrouter.ai/blog/announcing-audio-apis>
- Swift SDK source: `Sources/OpenRouter/Public/OpenRouterClient.swift`

Base URL:

```text
https://openrouter.ai/api/v1
```

Endpoint paths below are relative to the base URL.

Status legend:

- `[x]` Implemented in the SDK
- `[ ]` Not implemented yet

## Implementation Summary

| Status | Method | Path | SDK API | Notes |
|---|---|---|---|---|
| [x] | POST | `/chat/completions` | `client.chat.send`, `client.chat.stream`, `client.createChatCompletion*` | Non-streaming and SSE streaming chat completions, plus client-side fallback helpers. |
| [x] | POST | `/responses` | `client.responses.create`, `client.responses.stream`, `client.createResponse*` | Non-streaming and beta SSE Responses API, including flat function tools and stateless function-call/output and reasoning replay. Raw typed events expose text and function argument deltas. |
| [x] | POST | `/messages` | `client.messages.create`, `client.messages.stream`, `client.createMessage*` | Anthropic-compatible messages with typed content/tools and SSE streaming. |
| [x] | POST | `/embeddings` | `client.embeddings.create`, `client.createEmbeddings` | Text embedding requests. |
| [x] | GET | `/embeddings/models` | `client.embeddings.listModels`, `client.listEmbeddingsModels` | Lists embedding models with pagination. |
| [x] | POST | `/rerank` | `client.rerank.create`, `client.createRerank` | Reranks documents by relevance. |
| [x] | POST | `/audio/speech` | `client.audio.speech`, `client.createAudioSpeech` | Creates speech and returns raw audio bytes. |
| [x] | POST | `/audio/transcriptions` | `client.audio.transcribe`, `client.createAudioTranscriptions` | Creates an audio transcription with multipart upload. |
| [x] | POST | `/files` | `client.files.upload`, `client.uploadFile` | Uploads a file with an optional workspace ID. |
| [x] | POST | `/videos` | `client.videos.create`, `client.createVideos` | Creates an asynchronous video generation job. |
| [x] | GET | `/videos/{jobId}` | `client.videos.get`, `client.getVideos` | Polls a video generation job. |
| [x] | GET | `/videos/{jobId}/content` | `client.videos.content`, `client.listVideosContent` | Downloads buffered video data and its Content-Type. |
| [x] | GET | `/videos/models` | `client.videos.models.list`, `client.listVideosModels` | Lists video generation model capabilities. |
| [x] | POST | `/completions` | `client.createCompletion` | Legacy OpenAI-compatible text completions endpoint. |
| [x] | GET | `/generation` | `client.generations.get`, `client.getGeneration`, `client.getGenerationRaw` | Gets request and usage metadata for a generation. |
| [x] | GET | `/generation/content` | `client.generations.content`, `client.listGenerationContent`, `client.listGenerationContentRaw` | Gets stored prompt/completion content for a generation. |
| [x] | GET | `/models` | `client.models.list`, `client.listModels` | Lists available models. |
| [x] | GET | `/models/user` | `client.models.listUser`, `client.listModelsUser` | Lists user-filtered models with optional `offset` and `limit` pagination. |
| [x] | GET | `/model/{author}/{slug}` | `client.models.get`, `client.getModel` | Gets full details for one model. |
| [x] | GET | `/models/count` | `client.models.count`, `client.listModelsCount` | Gets the total available model count, optionally filtered by output modalities. |
| [x] | GET | `/credits` | `client.credits.get`, `client.getCredits` | Gets remaining credits and usage. Requires a management API key. |
| [x] | GET | `/activity` | `client.activity.get`, `client.getUserActivity` | Gets activity data for a management API key with optional filters and grouping. |
| [x] | GET | `/datasets/rankings-daily` | `client.datasets.rankingsDaily`, `client.getRankingsDaily` | Gets daily model rankings with optional filters and periods. |
| [x] | GET | `/providers` | `client.providers.list`, `client.listProviders` | Lists available providers. |
| [x] | GET | `/models/{author}/{slug}/endpoints` | `client.endpoints.list`, `client.listModelEndpoints` | Lists endpoints for a specific model. |
| [x] | GET | `/endpoints/zdr` | `client.endpoints.listZDR`, `client.listZDREndpoints` | Previews Zero Data Retention endpoint availability. |

## Core Inference Endpoints

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | POST | `/chat/completions` | `sendChatCompletionRequest` | Create a chat completion. | Implemented in `OpenRouterClient.createChatCompletion`; resource aliases: `client.chat.send` and `client.chat.stream`. Streaming uses the same endpoint with `stream: true`. |
| [x] | POST | `/responses` | `createResponses` | Create a response using the Responses API style. | Implemented in `OpenRouterClient.createResponse` and `createResponseStream`; resource aliases: `client.responses.create` and `client.responses.stream`. Supports flat function tools plus stateless function-call/output and reasoning replay, and beta SSE typed/raw events. |
| [x] | POST | `/messages` | `createMessages` | Create an Anthropic-compatible message. | Implemented in `OpenRouterClient.createMessage` and `createMessageStream`; resource aliases: `client.messages.create` and `client.messages.stream`. Supports typed native tools/content blocks and raw unknown extensions. |
| [x] | POST | `/embeddings` | `createEmbeddings` | Submit an embedding request. | Implemented in `OpenRouterClient.createEmbeddings`; resource alias: `client.embeddings.create`. |
| [x] | GET | `/embeddings/models` | `listEmbeddingsModels` | List embedding models. | Implemented in `OpenRouterClient.listEmbeddingsModels`; resource alias: `client.embeddings.listModels`. Supports optional `offset` and `limit` pagination parameters. |
| [x] | POST | `/rerank` | `createRerank` | Submit a rerank request. | Implemented in `OpenRouterClient.createRerank`; resource alias: `client.rerank.create`. |
| [x] | POST | `/audio/speech` | `createAudioSpeech` | Create speech from text. | Implemented in `OpenRouterClient.createAudioSpeech`; resource alias: `client.audio.speech`. Returns raw audio bytes. |
| [x] | POST | `/audio/transcriptions` | `createAudioTranscriptions` | Create a transcription from audio. | Implemented in `OpenRouterClient.createAudioTranscriptions`; resource alias: `client.audio.transcribe`. |
| [x] | POST | `/videos` | `createVideos` | Submit a video generation request. | Implemented in `OpenRouterClient.createVideos`; resource alias: `client.videos.create`. |
| [x] | GET | `/videos/{jobId}` | `getVideos` | Poll video generation job status. | Implemented in `OpenRouterClient.getVideos`; resource alias: `client.videos.get`. |
| [x] | GET | `/videos/{jobId}/content` | `listVideosContent` | Download generated video content. | Implemented in `OpenRouterClient.listVideosContent`; resource alias: `client.videos.content`. |
| [x] | GET | `/videos/models` | `listVideosModels` | List video generation models. | Implemented in `OpenRouterClient.listVideosModels`; resource alias: `client.videos.models.list`. |

## OpenAI-Compatible Legacy Endpoints

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | POST | `/completions` | `createCompletion` | Create a legacy text completion. | Implemented in `OpenRouterClient.createCompletion`. This endpoint is implemented by the SDK even though it is not listed in the Zig tracker summary. |

## Models, Providers, and Routing Discovery

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | GET | `/models` | `getModels` | List all models and their properties. | Implemented in `OpenRouterClient.listModels`; resource alias: `client.models.list`. |
| [x] | GET | `/model/{author}/{slug}` | `getModelBySlug` | Get full details for one model. | Implemented in `OpenRouterClient.getModel`; resource alias: `client.models.get`. Distinct from `/models/{author}/{slug}/endpoints`. |
| [x] | GET | `/models/count` | `listModelsCount` | Get the total count of available models. | Implemented in `OpenRouterClient.listModelsCount`; resource alias: `client.models.count`. Supports optional `output_modalities`. |
| [x] | GET | `/models/user` | `listModelsUser` | List models filtered by user preferences, privacy, or guardrails. | Implemented in `OpenRouterClient.listModelsUser`; resource alias: `client.models.listUser`. Supports optional `offset` and `limit` pagination. |
| [x] | GET | `/models/{author}/{slug}/endpoints` | `listEndpoints` | List endpoints for a specific model. | Implemented in `OpenRouterClient.listModelEndpoints`; resource alias: `client.endpoints.list`. |
| [x] | GET | `/providers` | `listProviders` | List all providers. | Implemented in `OpenRouterClient.listProviders`; resource alias: `client.providers.list`. |
| [x] | GET | `/endpoints/zdr` | `listEndpointsZdr` | Preview Zero Data Retention impact on available endpoints. | Implemented in `OpenRouterClient.listZDREndpoints`; resource alias: `client.endpoints.listZDR`. |

## Usage, Billing, and Generation Metadata

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | GET | `/credits` | `getCredits` | Get remaining credits. | Implemented in `OpenRouterClient.getCredits`; resource alias: `client.credits.get`. Requires a management API key. |
| [x] | GET | `/generation` | `getGeneration` | Get request and usage metadata for a generation. | Implemented in `OpenRouterClient.getGeneration`; resource alias: `client.generations.get`. Also has `getGenerationRaw`. |
| [x] | GET | `/generation/content` | `listGenerationContent` | Get stored prompt/completion content for a generation. | Implemented in `OpenRouterClient.listGenerationContent`; resource alias: `client.generations.content`. Also has `listGenerationContentRaw`. |
| [x] | GET | `/activity` | `getUserActivity` | Get user activity grouped by endpoint. Requires a management API key. | Implemented in `OpenRouterClient.getUserActivity`; resource alias: `client.activity.get`. Supports optional date, API key, user, workspace filters, and grouping. |
| [x] | GET | `/datasets/rankings-daily` | `getRankingsDaily` | Get daily token totals for top models. | Implemented in `OpenRouterClient.getRankingsDaily`; resource alias: `client.datasets.rankingsDaily`. Supports optional date, period, modality, context, category, and language filters. Valid inference keys are accepted and rate limited. |

## API Keys, Auth, and BYOK

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | GET | `/key` | `getCurrentKey` | Get the current API key. |  |
| [ ] | GET | `/keys` | `list` | List API keys. |  |
| [ ] | POST | `/keys` | `create` | Create a new API key. |  |
| [ ] | GET | `/keys/{hash}` | `get` | Get a single API key. |  |
| [ ] | PATCH | `/keys/{hash}` | `update` | Update an API key. |  |
| [ ] | DELETE | `/keys/{hash}` | `delete` | Delete an API key. |  |
| [ ] | POST | `/auth/keys/code` | `createAuthKeysCode` | Create an authorization code. |  |
| [ ] | POST | `/auth/keys` | `exchangeAuthCodeForAPIKey` | Exchange an authorization code for an API key. |  |
| [ ] | GET | `/byok` | `listBYOKKeys` | List BYOK provider credentials. Requires management auth. |  |
| [ ] | POST | `/byok` | `createBYOKKey` | Create a BYOK provider credential. |  |
| [ ] | GET | `/byok/{id}` | `getBYOKKey` | Get a BYOK provider credential. |  |
| [ ] | PATCH | `/byok/{id}` | `updateBYOKKey` | Update a BYOK provider credential. |  |
| [ ] | DELETE | `/byok/{id}` | `deleteBYOKKey` | Delete a BYOK provider credential. |  |

## Guardrails

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | GET | `/guardrails` | `listGuardrails` | List guardrails. Requires management auth. |  |
| [ ] | POST | `/guardrails` | `createGuardrail` | Create a guardrail. |  |
| [ ] | GET | `/guardrails/{id}` | `getGuardrail` | Get a guardrail. |  |
| [ ] | PATCH | `/guardrails/{id}` | `updateGuardrail` | Update a guardrail. |  |
| [ ] | DELETE | `/guardrails/{id}` | `deleteGuardrail` | Delete a guardrail. |  |
| [ ] | GET | `/guardrails/{id}/assignments/keys` | `listGuardrailKeyAssignments` | List key assignments for a guardrail. |  |
| [ ] | POST | `/guardrails/{id}/assignments/keys` | `bulkAssignKeysToGuardrail` | Bulk assign keys to a guardrail. |  |
| [ ] | POST | `/guardrails/{id}/assignments/keys/remove` | `bulkUnassignKeysFromGuardrail` | Bulk unassign keys from a guardrail. |  |
| [ ] | GET | `/guardrails/{id}/assignments/members` | `listGuardrailMemberAssignments` | List member assignments for a guardrail. |  |
| [ ] | POST | `/guardrails/{id}/assignments/members` | `bulkAssignMembersToGuardrail` | Bulk assign members to a guardrail. |  |
| [ ] | POST | `/guardrails/{id}/assignments/members/remove` | `bulkUnassignMembersFromGuardrail` | Bulk unassign members from a guardrail. |  |
| [ ] | GET | `/guardrails/assignments/keys` | `listKeyAssignments` | List all key assignments. |  |
| [ ] | GET | `/guardrails/assignments/members` | `listMemberAssignments` | List all member assignments. |  |

## Workspaces and Organization

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | GET | `/workspaces` | `listWorkspaces` | List workspaces. |  |
| [ ] | POST | `/workspaces` | `createWorkspace` | Create a workspace. |  |
| [ ] | GET | `/workspaces/{id}` | `getWorkspace` | Get a workspace. |  |
| [ ] | PATCH | `/workspaces/{id}` | `updateWorkspace` | Update a workspace. |  |
| [ ] | DELETE | `/workspaces/{id}` | `deleteWorkspace` | Delete a workspace. |  |
| [ ] | POST | `/workspaces/{id}/members/add` | `bulkAddWorkspaceMembers` | Bulk add members to a workspace. |  |
| [ ] | POST | `/workspaces/{id}/members/remove` | `bulkRemoveWorkspaceMembers` | Bulk remove members from a workspace. |  |
| [ ] | GET | `/organization/members` | `listOrganizationMembers` | List organization members. |  |

## Observability

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | GET | `/observability/destinations` | `listObservabilityDestinations` | List observability destinations. |  |
| [ ] | POST | `/observability/destinations` | `createObservabilityDestination` | Create an observability destination. |  |
| [ ] | GET | `/observability/destinations/{id}` | `getObservabilityDestination` | Get an observability destination. |  |
| [ ] | PATCH | `/observability/destinations/{id}` | `updateObservabilityDestination` | Update an observability destination. |  |
| [ ] | DELETE | `/observability/destinations/{id}` | `deleteObservabilityDestination` | Delete an observability destination. |  |

## Files

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | POST | `/files` | `uploadFile` | Upload a file for later API calls. | Implemented in `OpenRouterClient.uploadFile`; resource alias: `client.files.upload`. |

## Preset Configuration Endpoints

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | POST | `/presets/{slug}/chat/completions` | `createPresetsChatCompletions` | Create or update a preset from a chat-completions-shaped body. | Does not execute inference. |
| [ ] | POST | `/presets/{slug}/messages` | `createPresetsMessages` | Create or update a preset from a Messages-shaped body. | Does not execute inference. |
| [ ] | POST | `/presets/{slug}/responses` | `createPresetsResponses` | Create or update a preset from a Responses-shaped body. | Does not execute inference. |

## Notes

- Update the status checkbox and SDK notes when implementing a new endpoint.
- Keep public method names and resource aliases in sync with `OpenRouterClient.swift`.
- OpenRouter-specific request features implemented inside existing endpoints, such as provider routing, reasoning, web search options, response caching, multimodal content parts, and fallback helpers, are not tracked as separate endpoints here.
- The OpenAPI spec is the best source of truth for endpoint inventory because it includes endpoints beyond chat and model listing.
