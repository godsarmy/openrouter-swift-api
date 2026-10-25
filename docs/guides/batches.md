---
type: Guide
title: Batch processing
description: Submit inline batch requests and explicitly retrieve status and results.
tags: [batches, asynchronous, inference, billing]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: https://openrouter.ai/docs/batch-quickstart
    title: OpenRouter Batch API Quickstart
---

# Batch processing

Use a [configured client](../getting-started/quick-start.md) to create a batch,
list jobs, or retrieve one job. **Creating a batch submits real provider work and
can incur charges.** The SDK does not submit jobs, poll, or execute callbacks
automatically. Normal tests use mocked responses, not live submissions.

## Build and explicitly submit

The current API takes **inline request objects**, not an uploaded JSONL input
file. All requests in a batch share one model and endpoint. Each `customID` must
be nonempty and unique within that batch. If a request body includes `model`, it
must match the batch's model.

```swift
let batchRequest = CreateBatchRequest(
  endpoint: "/v1/embeddings",
  model: "openai/text-embedding-3-small",
  requests: [
    .init(customID: "embedding-1", body: ["input": .string("Hello, world")])
  ],
  completionWindow: "24h"
)
// Submits real work and may incur cost. Uncomment only when intentional:
// let submitted = try await client.batches.create(
//   batchRequest, options: .init(retries: RetryPolicy.none)
// )
```

Supported endpoint values are `/v1/chat/completions`, `/v1/responses`,
`/v1/messages`, and `/v1/embeddings`. Endpoint strings remain open for forward
compatibility; the server validates supported values and request contents.
Each request body is `[String: JSONValue]`, preserving endpoint-specific fields.

Optional `BatchProviderPreferences` exposes only `only` and `allowFallbacks`;
do not pass the broader synchronous provider-routing options. An optional
`callbackURL` must use HTTPS. The SDK does not implement a webhook receiver.
The current completion window is `"24h"` (also the server default when omitted).
The server validates these constraints and the 200 MB submission limit.

OpenRouter requires `endpoint`, `model`, `provider`, `completion_window`, and
`callback_url`, when present, to precede `requests` in the JSON document.
`createBatch` uses sorted-key encoding to satisfy this wire-order requirement.
Ordinary `JSONEncoder` encoding outside that API does not guarantee this order.

HTTP **202** returns a `BatchObject`, initially in `validating` status. Acceptance
does not mean provider validation or processing has succeeded. Retries default
to disabled; do not automatically resubmit after a transport failure because the
original batch may already have been accepted.

## List and retrieve

```swift
let batchesPage = try await client.batches.list(
  limit: 20, statuses: ["completed", "failed"], createdAfter: "2026-10-01"
)
if batchesPage.hasMore, let lastID = batchesPage.lastID {
  let nextPage = try await client.batches.list(
    limit: 20, after: lastID, statuses: ["completed", "failed"],
    createdAfter: "2026-10-01"
  )
  // Consume nextPage in your app; pagination is explicit.
}
// Replace this placeholder with an existing job ID:
let batch = try await client.batches.get(id: "batch_example")
let status = batch.status
let counts = batch.requestCounts
for result in batch.results ?? [] {
  let customID = result.customID
  let responseBody = result.response?.body // JSONValue for the submitted endpoint.
  let requestError = result.error
  // Correlate customID and inspect response/error explicitly.
}
```

Flat aliases are `createBatch`, `listBatches`, and `getBatch`. All accept
`RequestOptions` and use normal API-key authentication. Jobs are scoped to the
authenticating key's workspace; these operations do not take workspace/provider
query filters. The provider is selected through the creation body's routing
preferences and returned in job metadata.

Listing is newest-first. `limit` accepts 1–100, and `after` uses the previous
page's `lastID`. `statuses` becomes repeated `status` query parameters, not a
comma-separated string. Supported list filters are `validating`, `in_progress`,
`completed`, `failed`, `expired`, and `cancelled`. `createdAfter` and
`createdBefore` are strict bounds, passed through as digit timestamp strings,
dates, or date-times. Keep all filters when advancing to another page.

List items have no results (`results` is null); retrieve a job to access them.
Retrieved statuses also include `finalizing` and `cancelling`. Status and provider
strings remain open for future values. There is no automatic polling or terminal
state inference in the SDK.

## Results, billing, and retention

`BatchObject` exposes request counts, Unix timestamps, nullable usage/results,
provider information, and batch-level errors. Per-request results retain their
`customID`, HTTP status/request ID, raw `JSONValue` response body, and error
details. Do not assume every body is a chat completion: the batch endpoint may
instead produce Responses, Messages, or embedding results. Usage remains raw
JSON to preserve provider-specific accounting fields.

The object and list envelope retain `rawPayload`, including unmodeled fields.
Encoding uses that payload; editing a typed response property alone does not
rewrite the authoritative JSON. A successful HTTP response can still describe a
failed batch, so inspect `status`, the batch error, and each request result.

Creation can return HTTP 402 when the estimated cost exceeds the available
balance. Retrieval can also return **402 with batch metadata but withheld
results** until credits cover the finalized charge. This surfaces as
`OpenRouterError.apiError`; its `rawBody` retains the metadata, not a successful
`BatchObject` return. Do not resubmit the work to resolve that payment condition.

Save needed results: upstream requests/results expire 30 days after submission,
after which retrieval returns HTTP 410. `expiresAt` is instead the assigned
provider's processing deadline: it may exceed 24 hours or be null, and is not the
result-retention deadline. Batch deletion remains unimplemented.

See [endpoint coverage](../reference/endpoint-coverage.md) for current scope and
[file retrieval](resources.md#file-retrieval) for separate file operations.
