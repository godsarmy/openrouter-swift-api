---
type: Reference
title: Endpoint coverage
description: Track implemented OpenRouter endpoints, SDK aliases, and deferred endpoint work.
tags: [api, coverage, roadmap]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/OpenRouterClient.swift
    title: SDK client implementation
---

# OpenRouter API Implementation Tracker

See the [documentation index](../index.md), [resource examples](../guides/resources.md),
and [current limitations](limitations.md) for usage and compatibility context.

This file tracks which OpenRouter API endpoints are implemented by this Swift SDK.

## Audit source and scope

Endpoint inventory checked on **2026-10-25** against a fresh download of the
official OpenAPI specification (OpenAPI 3.1.0, `info.version: 1.0.0`).

| Inventory | Unique method/path operations |
|---|---:|
| Listed in the current specification | 139 |
| Current-spec operations implemented by the SDK | 42 |
| Current-spec operations not implemented | 97 |
| Additional SDK legacy operations absent from the specification | 1 |

The earlier tracker omitted 72 current-spec operations; those are now included
below. Table statuses reflect subsequent SDK additions. Repeated summary/detail rows do
not count as separate operations. Coverage is matched by **HTTP method and path**:
`POST /files` upload does not implement `GET /files` listing.

This is an endpoint-presence audit, not a complete request/response field-parity
or live authorization audit. Spec-listed alpha and specialized management APIs
are inventory entries, not a claim that every account can access them or that
their contracts are stable. Absence from the spec alone does not prove that an
existing endpoint was removed or deprecated.

Sources:

- API reference overview: <https://openrouter.ai/docs/api/reference/overview>
- OpenAPI spec: <https://openrouter.ai/openapi.json>
- Audio API announcement: <https://openrouter.ai/blog/announcing-audio-apis>
- Swift SDK source: `Sources/OpenRouter/Public/OpenRouterClient.swift`

Base URL:

```text
https://openrouter.ai/api/v1
```

Endpoint paths below are relative to the base URL, except
`POST /api/alpha/decisions`: its operation-level server override is
`https://openrouter.ai`, so its full URL is
`https://openrouter.ai/api/alpha/decisions`.

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
| [x] | GET | `/files` | `client.files.list`, `client.listFiles` | Lists files with workspace/provider filters and explicit pagination fields. |
| [x] | GET | `/files/{file_id}` | `client.files.get`, `client.getFile` | Gets native or provider-shaped file metadata without changing the upload response type. |
| [x] | GET | `/files/{file_id}/content` | `client.files.content`, `client.downloadFileContent` | Downloads buffered bytes and an optional Content-Type. Only server-created files are downloadable. |
| [x] | DELETE | `/files/{file_id}` | `client.files.delete`, `client.deleteFile` | Irreversibly deletes a file with optional workspace/provider scoping and a typed confirmation. |
| [x] | POST | `/batches` | `client.batches.create`, `client.createBatch` | Submits inline requests for asynchronous validation/processing; HTTP 202. Can incur provider cost. |
| [x] | GET | `/batches` | `client.batches.list`, `client.listBatches` | Lists workspace-scoped jobs with cursor, repeated status, and creation-time filters. |
| [x] | GET | `/batches/{id}` | `client.batches.get`, `client.getBatch` | Retrieves typed metadata and endpoint-specific raw result bodies; payment/retention failures remain API errors. |
| [x] | POST | `/videos` | `client.videos.create`, `client.createVideos` | Creates an asynchronous video generation job. |
| [x] | GET | `/videos/{jobId}` | `client.videos.get`, `client.getVideos` | Polls a video generation job. |
| [x] | GET | `/videos/{jobId}/content` | `client.videos.content`, `client.listVideosContent` | Downloads buffered video data and its Content-Type. |
| [x] | GET | `/videos/models` | `client.videos.models.list`, `client.listVideosModels` | Lists video generation model capabilities. |
| [x] | POST | `/completions` | `client.createCompletion` | Legacy SDK support; absent from the audited current OpenAPI specification. |
| [x] | GET | `/generation` | `client.generations.get`, `client.getGeneration`, `client.getGenerationRaw` | Gets request and usage metadata for a generation. |
| [x] | GET | `/generation/content` | `client.generations.content`, `client.listGenerationContent`, `client.listGenerationContentRaw` | Gets stored prompt/completion content for a generation. |
| [x] | GET | `/models` | `client.models.list`, `client.listModels` | Lists available models. |
| [x] | GET | `/models/user` | `client.models.listUser`, `client.listModelsUser` | Lists user-filtered models with optional `offset` and `limit` pagination. |
| [x] | GET | `/model/{author}/{slug}` | `client.models.get`, `client.getModel` | Gets full details for one model. |
| [x] | GET | `/models/count` | `client.models.count`, `client.listModelsCount` | Gets the total available model count, optionally filtered by output modalities. |
| [x] | GET | `/credits` | `client.credits.get`, `client.getCredits` | Gets remaining credits and usage. Requires a management API key. |
| [x] | GET | `/key` | `client.keys.current`, `client.getCurrentKey` | Gets usage, limits, and lifecycle metadata for the current key using ordinary bearer key authentication. |
| [x] | GET | `/keys` | `client.keys.list`, `client.listAPIKeys` | Lists management API key metadata with optional disabled, offset, and workspace filters. Requires a management key. |
| [x] | GET | `/keys/{hash}` | `client.keys.get`, `client.getAPIKey` | Gets management API key metadata. Requires a management key; no plaintext secret is returned. |
| [x] | POST | `/keys` | `client.keys.create`, `client.createAPIKey` | Creates a management API key and returns its one-time plaintext secret response. Requires a management key. |
| [x] | PATCH | `/keys/{hash}` | `client.keys.update`, `client.updateAPIKey` | Updates management key metadata. Nullable `limit` and `limit_reset` can be explicitly cleared; no plaintext secret is returned. |
| [x] | DELETE | `/keys/{hash}` | `client.keys.delete`, `client.deleteAPIKey` | Permanently deletes a management API key and returns a typed deletion confirmation. Requires a management key. |
| [x] | POST | `/auth/keys/code` | `client.auth.keys.createCode`, `client.createAuthKeysCode` | Creates a management-key authorization code with optional PKCE; codes are single-use and expire after approximately 10 minutes. |
| [x] | POST | `/auth/keys` | `client.auth.keys.exchange`, `client.exchangeAuthCodeForAPIKey` | Exchanges a code with optional PKCE for a plaintext API key and nullable user ID. No bearer authentication is sent. |
| [x] | GET | `/activity` | `client.activity.get`, `client.getUserActivity` | Gets activity data for a management API key with optional filters and grouping. |
| [x] | GET | `/datasets/rankings-daily` | `client.datasets.rankingsDaily`, `client.getRankingsDaily` | Gets daily model rankings with optional filters and periods. |
| [x] | GET | `/providers` | `client.providers.list`, `client.listProviders` | Lists available providers. |
| [x] | GET | `/models/{author}/{slug}/endpoints` | `client.endpoints.list`, `client.listModelEndpoints` | Lists endpoints for a specific model. |
| [x] | GET | `/endpoints/zdr` | `client.endpoints.listZDR`, `client.listZDREndpoints` | Previews Zero Data Retention endpoint availability. |
| [x] | GET | `/workspaces` | `client.workspaces.list`, `client.listWorkspaces` | Lists workspaces with optional offset/limit pagination and a total count. Requires a management key. |
| [x] | GET | `/workspaces/{id}` | `client.workspaces.get`, `client.getWorkspace` | Gets a workspace by UUID or slug, safely encoded as one path segment. Requires a management key. |

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
| [x] | POST | `/completions` | `createCompletion` | Create a legacy text completion. | Implemented in `OpenRouterClient.createCompletion`. Absent from the OpenAPI specification audited on 2026-10-25; retained as SDK compatibility support. Spec absence alone is not proof of deprecation or removal. |

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
| [x] | GET | `/key` | `getCurrentKey` | Get usage, limits, and lifecycle metadata for the current API key. | Implemented in `OpenRouterClient.getCurrentKey`; resource alias: `client.keys.current`. Supports ordinary bearer API keys and does not expose key material. |
| [x] | GET | `/keys` | `list` | List API key metadata. | Implemented in `OpenRouterClient.listAPIKeys`; resource alias: `client.keys.list`. Requires a management key and supports `include_disabled`, `offset`, and `workspace_id` filters. |
| [x] | POST | `/keys` | `create` | Create a new API key. | Implemented in `OpenRouterClient.createAPIKey`; resource alias: `client.keys.create`. Requires a management key; the plaintext key response is returned once and must be stored securely. |
| [x] | GET | `/keys/{hash}` | `get` | Get a single API key. | Implemented in `OpenRouterClient.getAPIKey`; resource alias: `client.keys.get`. Requires a management key and returns metadata only, never plaintext key material. |
| [x] | PATCH | `/keys/{hash}` | `update` | Update an API key. | Implemented in `OpenRouterClient.updateAPIKey`; resource alias: `client.keys.update`. Requires a management key, returns metadata only, and supports explicit null to clear nullable `limit` and `limit_reset`. |
| [x] | DELETE | `/keys/{hash}` | `delete` | Permanently delete an API key. | Implemented in `OpenRouterClient.deleteAPIKey`; resource alias: `client.keys.delete`. Requires a management key and returns `DeleteAPIKeyResponse(deleted: true)` on successful confirmation. |
| [x] | POST | `/auth/keys/code` | `createAuthKeysCode` | Create an authorization code. | Implemented in `OpenRouterClient.createAuthKeysCode`; resource alias: `client.auth.keys.createCode`. Requires a management key; supports PKCE and returns a single-use code that expires after approximately 10 minutes. |
| [x] | POST | `/auth/keys` | `exchangeAuthCodeForAPIKey` | Exchange an authorization code for an API key. | Implemented in `OpenRouterClient.exchangeAuthCodeForAPIKey`; resource alias: `client.auth.keys.exchange`. Supports optional PKCE verifier/method, requires no bearer key, and redacts credential descriptions. |
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
| [x] | GET | `/workspaces` | `listWorkspaces` | List workspaces. | Implemented in `OpenRouterClient.listWorkspaces`; alias: `client.workspaces.list`. Optional `offset` and `limit`; typed `WorkspacesResponse` includes `totalCount`. Requires a management key. |
| [ ] | POST | `/workspaces` | `createWorkspace` | Create a workspace. |  |
| [x] | GET | `/workspaces/{id}` | `getWorkspace` | Get a workspace. | Implemented in `OpenRouterClient.getWorkspace`; alias: `client.workspaces.get`. Accepts a UUID or slug string; returns `WorkspaceResponse`. Requires a management key. |
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

## Batch Processing

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | POST | `/batches` | `createBatches` | Submit a batch. | Implemented in `OpenRouterClient.createBatch`; alias: `client.batches.create`. Inline requests with one endpoint/model; not an uploaded input file. Submission can incur charges. |
| [x] | GET | `/batches` | `listBatches` | List jobs. | Implemented in `OpenRouterClient.listBatches`; alias: `client.batches.list`. Supports `limit`, `after`, repeated `status`, `created_after`, and `created_before`. |
| [x] | GET | `/batches/{id}` | `getBatches` | Retrieve a job. | Implemented in `OpenRouterClient.getBatch`; alias: `client.batches.get`. Uses a safely escaped ID. Results remain JSON per submitted endpoint; no automatic polling or deletion. |

## Files

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [x] | POST | `/files` | `uploadFile` | Upload a file for later API calls. | Implemented in `OpenRouterClient.uploadFile`; resource alias: `client.files.upload`. |
| [x] | GET | `/files` | `listFiles` | List files. | Implemented in `OpenRouterClient.listFiles`; alias: `client.files.list`. Supports `limit`, `cursor`, `workspace_id`, `provider`, `after`, `after_id`, `before_id`, and `order`. |
| [x] | GET | `/files/{file_id}` | `getFileMetadata` | Retrieve metadata. | Implemented in `OpenRouterClient.getFile`; alias: `client.files.get`. Supports workspace/provider filters and typed response-shape variants. |
| [x] | GET | `/files/{file_id}/content` | `downloadFileContent` | Download file bytes. | Implemented in `OpenRouterClient.downloadFileContent`; alias: `client.files.content`. Supports workspace/provider filters; buffers the download and retains optional Content-Type. |
| [x] | DELETE | `/files/{file_id}` | `deleteFile` | Permanently delete a file. | Implemented in `OpenRouterClient.deleteFile`; alias: `client.files.delete`. Supports workspace/provider filters. Known response shapes validate deletion markers; unknown shapes are not confirmed success. |

File deletion is explicit and irreversible. Upload remains
native-storage-only in this SDK; the new retrieval provider option does not change
the existing upload API.

## Preset Configuration Endpoints

| Status | Method | Path | Operation | Description | SDK notes |
|---|---|---|---|---|---|
| [ ] | POST | `/presets/{slug}/chat/completions` | `createPresetsChatCompletions` | Create or update a preset from a chat-completions-shaped body. | Does not execute inference. |
| [ ] | POST | `/presets/{slug}/messages` | `createPresetsMessages` | Create or update a preset from a Messages-shaped body. | Does not execute inference. |
| [ ] | POST | `/presets/{slug}/responses` | `createPresetsResponses` | Create or update a preset from a Responses-shaped body. | Does not execute inference. |

## Additional spec-listed operations

These 65 operations were missing from the earlier tracker and have no SDK
implementation. Names in the last column are upstream operation IDs, **not**
existing Swift methods. Check each operation's schema, authentication,
availability, and server override before implementing it.

| Status | Method | Path | Upstream operation ID |
|---|---|---|---|
| [ ] | DELETE | `/batches/{id}` | `deleteBatch` |
| [ ] | DELETE | `/external-users/{user}` | `deleteExternalUser` |
| [ ] | DELETE | `/private-endpoints/{id}` | `deletePrivateEndpoint` |
| [ ] | DELETE | `/scim/group-mappings/{id}` | `deleteScimGroupMapping` |
| [ ] | DELETE | `/vault/interns/{internId}/secrets/{name}` | `deleteInternVaultSecret` |
| [ ] | DELETE | `/vault/secrets/{name}` | `deleteVaultSecret` |
| [ ] | DELETE | `/workspaces/{workspace_ref}/budgets/{interval}` | `deleteWorkspaceBudget` |
| [ ] | GET | `/analytics/meta` | `getAnalyticsMeta` |
| [ ] | GET | `/benchmarks` | `getBenchmarks` |
| [ ] | GET | `/classifications/task` | `getTaskClassifications` |
| [ ] | GET | `/containers/{container_id}/files` | `listContainerFiles` |
| [ ] | GET | `/containers/{container_id}/files/{file_id}` | `getContainerFile` |
| [ ] | GET | `/containers/{container_id}/files/{file_id}/content` | `downloadContainerFileContent` |
| [ ] | GET | `/datasets/app-rankings` | `getAppRankings` |
| [ ] | GET | `/datasets/session-cost` | `getSessionCost` |
| [ ] | GET | `/external-users` | `listExternalUsers` |
| [ ] | GET | `/external-users/{user}` | `getExternalUser` |
| [ ] | GET | `/images/models` | `listImageModels` |
| [ ] | GET | `/images/models/{author}/{slug}/endpoints` | `listImageModelEndpoints` |
| [ ] | GET | `/oauth/jwks` | `listOauthJwks` |
| [ ] | GET | `/organization/settings` | `getOrganizationSettings` |
| [ ] | GET | `/presets` | `listPresets` |
| [ ] | GET | `/presets/{slug}` | `getPreset` |
| [ ] | GET | `/presets/{slug}/versions` | `listPresetVersions` |
| [ ] | GET | `/presets/{slug}/versions/{version}` | `getPresetVersion` |
| [ ] | GET | `/private-endpoints` | `listPrivateEndpoints` |
| [ ] | GET | `/private-endpoints/{id}` | `getPrivateEndpoint` |
| [ ] | GET | `/scim/group-mappings` | `listScimGroupMappings` |
| [ ] | GET | `/scim/group-mappings/{id}` | `getScimGroupMapping` |
| [ ] | GET | `/scim/groups` | `listScimGroups` |
| [ ] | GET | `/scim/sync-jobs/{id}` | `getScimSyncJob` |
| [ ] | GET | `/tools` | `listTools` |
| [ ] | GET | `/tools/{name}` | `getTool` |
| [ ] | GET | `/vault/interns/{internId}/connections` | `listInternConnections` |
| [ ] | GET | `/vault/interns/{internId}/effective-secrets` | `listInternEffectiveVaultSecrets` |
| [ ] | GET | `/vault/interns/{internId}/secrets` | `listInternVaultSecrets` |
| [ ] | GET | `/vault/secrets` | `listVaultSecrets` |
| [ ] | GET | `/workspaces/{workspace_ref}/budgets` | `listWorkspaceBudgets` |
| [ ] | GET | `/workspaces/{workspace_ref}/budgets/{interval}` | `getWorkspaceBudget` |
| [ ] | GET | `/workspaces/{id}/members` | `listWorkspaceMembers` |
| [ ] | PATCH | `/external-users/{user}` | `updateExternalUser` |
| [ ] | PATCH | `/organization/settings` | `updateOrganizationSettings` |
| [ ] | PATCH | `/private-endpoints/{id}` | `updatePrivateEndpoint` |
| [ ] | PATCH | `/scim/group-mappings/{id}` | `updateScimGroupMapping` |
| [ ] | POST | `/analytics/query` | `queryAnalytics` |
| [ ] | POST | `/api/alpha/decisions` | `createApiAlphaDecisions` |
| [ ] | POST | `/containers/{container_id}/files/{file_id}/promote` | `promoteContainerFile` |
| [ ] | POST | `/credits/coinbase` | `createCoinbaseCharge` |
| [ ] | POST | `/external-users` | `createExternalUser` |
| [ ] | POST | `/generation/feedback` | `submitGenerationFeedback` |
| [ ] | POST | `/images` | `createImages` |
| [ ] | POST | `/oauth/token` | `createOauthToken` |
| [ ] | POST | `/private-endpoints` | `createPrivateEndpoint` |
| [ ] | POST | `/private-endpoints/{id}/activate` | `activatePrivateEndpoint` |
| [ ] | POST | `/private-endpoints/{id}/disable` | `disablePrivateEndpoint` |
| [ ] | POST | `/private-endpoints/{id}/enable` | `enablePrivateEndpoint` |
| [ ] | POST | `/private-endpoints/{id}/validate` | `validatePrivateEndpoint` |
| [ ] | POST | `/scim/group-mappings` | `createScimGroupMapping` |
| [ ] | POST | `/scim/sync-jobs` | `createScimSyncJob` |
| [ ] | POST | `/systemone` | `createSystemone` |
| [ ] | POST | `/vault/interns/{internId}/secrets/copy` | `copyVaultSecretsToIntern` |
| [ ] | PUT | `/private-endpoints/{id}/pricing` | `updatePrivateEndpointPricing` |
| [ ] | PUT | `/vault/interns/{internId}/secrets/{name}` | `storeInternVaultSecret` |
| [ ] | PUT | `/vault/secrets/{name}` | `storeVaultSecret` |
| [ ] | PUT | `/workspaces/{workspace_ref}/budgets/{interval}` | `upsertWorkspaceBudget` |

## Notes

- Update the status checkbox and SDK notes when implementing a new endpoint.
- Keep public method names and resource aliases in sync with `OpenRouterClient.swift`.
- OpenRouter-specific request features implemented inside existing endpoints, such as provider routing, reasoning, web search options, response caching, multimodal content parts, and fallback helpers, are not tracked as separate endpoints here.
- The OpenAPI spec is the best source of truth for endpoint inventory because it includes endpoints beyond chat and model listing.
