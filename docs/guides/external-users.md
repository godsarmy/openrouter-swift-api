---
type: Guide
title: External users
description: Register caller-supplied tracking IDs and manage registration state without creating login accounts or enforcing inference access.
tags: [external-users, management, tracking, registrations]
sources:
  - resource: https://openrouter.ai/openapi.json
    title: OpenRouter OpenAPI specification
  - resource: ../../Sources/OpenRouter/Public/ExternalUser.swift
    title: External-user models
---

# External users

Use a [configured client](../getting-started/quick-start.md) with a **management
API key**, in an async context. These operations manage tracking-ID registrations
belonging to the authenticated organization. Registration creates no login
account, credentials, or policy. Active/inactive state is **not** an inference
authorization decision.

## List and retrieve

```swift
let registrations = try await client.externalUsers.list(
  offset: 0, limit: 25, includeInactive: true
)
let totalRegistrations = registrations.totalCount
if let user = registrations.data.first?.user {
  let registration = try await client.externalUsers.get(user: user)
  let isActive = registration.data.isActive
}
```

List accepts optional `offset`, `limit`, `user`, and `includeInactive` filters;
there is no workspace filter. Omitted pagination uses server defaults 0/50;
the server validates offset >= 0 and limit 1–100. Inactive registrations are
excluded by default. Explicit `includeInactive: false` or `offset: 0` are sent,
not treated as omitted. Pagination is manual; `totalCount` is the integer count
matching filters before pagination, not just the current page's size.

`ExternalUser` contains `user`, `isActive`, `createdAt`, and `updatedAt`, all
required and nonnullable. Times remain API strings. Get can retrieve active or
inactive registrations.

## Tracking IDs

The caller supplies `user`; the API does not return a generated replacement ID.
It is the immutable, case-sensitive tracking string used as inference `user` or
API-key `external.user`. The server requires 1–512 characters, well-formed Unicode,
no NUL, and no surrounding whitespace. The SDK passes these values through rather
than normalizing case, trimming, or renaming identity. Treat identifiers as
sensitive application metadata and avoid embedding credentials or unnecessary PII.

Path operations escape the entire tracking ID as one segment, including slashes,
spaces, percent signs, and Unicode. The spec says the IDs `.` and `..` cannot be
addressed by path. Get/update/delete reject them locally with
`OpenRouterError.invalidURL`; use the list filter to look them up instead:

```swift
let dotRegistration = try await client.externalUsers.list(user: ".", includeInactive: true)
```

Create and list do not reject these two values simply because they are not
path-addressable. Other identifier and pagination bounds remain server-validated.

## Register and update state

These operations change registration state. Approve the tracking ID and intended
change before running:

```swift
let registered = try await client.externalUsers.create(.init(user: "employee_123"))
let active = try await client.externalUsers.update(
  user: registered.data.user, .init(isActive: true)
)
// Deactivates the registration; does not block inference or erase its tracking ID:
// try await client.externalUsers.delete(user: registered.data.user)
```

Create takes only the tracking string and returns HTTP **201** with the
registration. An already-registered ID returns HTTP **409**, whether the existing
registration is active or inactive. Use PATCH to reactivate, not create again.

PATCH requires `isActive`, including an explicit false when deactivating; it does
not rename the identity. Get/update return HTTP **200** with registration data.
The SDK does not infer additional nullable settings, profiles, access controls,
or credentials from this small registration model.

## Deletion is deactivation

DELETE soft-deactivates the registration while retaining the tracking ID. The
reviewed specification says repeat deactivation succeeds and PATCH can reactivate
it. This operation **does not block inference** and is not hard deletion or a
guarantee of erasing historical data.

Success is HTTP **204** with no JSON body. The Swift delete method returns `Void`;
it does not fabricate a `deleted: true` response or try to decode an empty body.
Other successful-status codes are rejected as an invalid response on this
no-content operation, and API errors use the usual typed error mapping.

## Aliases and limits

Flat aliases are `listExternalUsers`, `createExternalUser`, `getExternalUser`,
`updateExternalUser`, and `deleteExternalUser`. Every method accepts per-request
`RequestOptions`, including headers and existing opt-in retry behavior. Retries
default to disabled. Do not infer create idempotency or blindly retry ambiguous
registration failures from the repeat-deactivation guarantee.

Authentication, permission, invalid input, missing registrations, duplicate IDs,
and server failures propagate as normal typed API errors. Cancellation and
network failures are not treated as successful deactivation.

Contract review uses the verified **October 31** OpenAPI snapshot; a fresh
November 3 snapshot was not successfully saved and validated. Offline fixtures
establish SDK wire behavior, not live account access or inference authorization.
No live registrations, state changes, or inference requests were used for
validation. See [endpoint coverage](../reference/endpoint-coverage.md) and the
[parity plan](../../PLAN.md) for remaining work.
