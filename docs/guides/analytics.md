---
type: Guide
title: Analytics queries
description: Discover analytics metrics and query usage with dimensions, filters, and classifier tags.
tags: [analytics, usage, management]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/Analytics.swift
    title: Analytics request and response models
  - resource: ../../Sources/OpenRouter/Public/Client/OpenRouterClient+Analytics.swift
    title: Analytics client methods
---

# Analytics queries

Both analytics endpoints require a management API key. Discover the available
query vocabulary before selecting metrics, dimensions, operators, and time buckets:

```swift
let client = OpenRouterClient(apiKey: managementKey)
let meta = try await client.analytics.getMeta()
let result = try await client.analytics.query(
  AnalyticsQueryRequest(
    metrics: ["request_count"],
    dimensions: ["model"],
    filters: [
      AnalyticsFilter(field: "model", operator: "eq", value: .string("openai/gpt-4o"))
    ],
    granularity: "day",
    limit: 100,
    orderBy: AnalyticsOrderBy(field: "request_count", direction: "desc"),
    timeRange: AnalyticsTimeRange(
      start: "2026-11-01T00:00:00Z", end: "2026-11-02T00:00:00Z")))
let rows = result.data.data
let truncated = result.data.metadata.truncated
```

The direct methods are `getAnalyticsMeta(options:)` and
`queryAnalytics(_:options:)`. Both aliases also accept request options, including
base URL, timeout, headers, and retry policy. API and decoding failures use the
normal SDK error types. A missing API key fails before sending a request.

## Query shape and server validation

`metrics` is required and must contain at least one name. The server accepts up to
two standard dimensions and twenty standard filters. Scalar filter values are
strings or numbers; set filter values are arrays of strings/numbers. Set filters
can use `includeUnset` to include the dimension's unset bucket. Filter values use
`JSONValue`; the server validates value shapes and operator combinations. Names,
operators, display formats, granularities, and ordering directions remain strings
so future server vocabulary can be used without an SDK update.

Filters use underlying identifiers even when response dimensions display labels:
model permaslugs, workspace UUIDs, Clerk user IDs, numeric app IDs, and API key
numeric IDs or key hashes. Use the metadata endpoint for available dimensions.
UTC timestamps must include seconds; fractional seconds are preserved as strings.

Optional fields are omitted when nil, leaving defaults to the server. The total
row limit defaults to 1000; time-series queries with dimensions may raise it when
`groupLimit` is omitted. An explicit `groupLimit` can truncate time buckets and is
ignored without dimensions. The SDK does not fetch additional results automatically.

## Classifier tags and results

`classifierDimensions` groups by tags from an active classifier on the workspace.
Supply its `classifierID`, optionally up to two `dimensionNames`, and optionally
`includeNulls`. Without dimension names, results use `clf_dimension_name` and
`clf_dimension_value` columns; named dimensions become their own column keys.

`classifierFilters` accepts a classifier ID and one to ten
`AnalyticsClassifierFilter` values. It can be used independently or alongside
classifier grouping; when combined, both classifier IDs must match. Explicit false
values for `includeNulls` and `includeUnset` are sent unchanged.

Rows are `[[String: JSONValue]]`, preserving dynamic metric/dimension columns,
null values, and nested extensions. `metadata` supplies `queryTimeMS`, `rowCount`,
and `truncated`. Check truncation and optional `warnings`, which can report
unresolved filter values even when the query succeeds. Optional `cachedAt` retains
the server's numeric value without assuming a timestamp unit.

## Contract baseline

These two operations and referenced schemas were checked against the official
specification retrieved on November 4, 2026 (SHA-256
`08855d8f74f3f44be3b3007576d79aee13faa6ecf6fd5cd790fcd78b51e6a4fb`).
Offline fixtures cover request serialization and response decoding; no live
management-key request was made. Classifier options and unset-bucket filtering
extend the sibling Zig implementation inspected during this change; cross-SDK
field parity remains follow-up work. The full endpoint inventory remains dated
October 31; see [endpoint coverage](../reference/endpoint-coverage.md).
