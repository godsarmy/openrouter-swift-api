# Documentation update log

## 2026-10-25

- **Creation**: Added batch processing guidance for inline requests, explicit costly submission, status/results, wire ordering, billing, and retention; updated navigation and endpoint coverage.
- **Update**: Documented explicit file deletion, approval and retry cautions, confirmation handling, and updated endpoint coverage.
- **Update**: Documented file retrieval, provider response shapes, pagination and download limits, and updated endpoint coverage without claiming provider-backed upload support.
- **Update**: Added workspace list/get examples, management-key and pagination guidance, and updated endpoint counts and deferred workspace scope.
- **Correction**: Reconciled endpoint coverage with the current official OpenAPI inventory, added 72 omitted operations, distinguished legacy completions, and corrected method-aware file coverage and the alpha decision server override. Removed stale Zig-tracker wording and documented audit limits.
- **Update**: Finalized v0.4.0 release-date and migration documentation.

## 2026-10-24

- **Update**: Prepared v0.4.0 compatibility and migration notes while retaining an explicit unreleased status.
- **Correction**: Added an explicit cancellation check before stream finalization, clarified per-choice call-ID uniqueness, and retained tool schemas in follow-up requests.
- **Update**: Documented streaming tool-call assembly, typed-helper integration, and completion/error boundaries; updated limitations and guide navigation.

## 2026-10-23

- **Correction**: Documented explicit null chat content support, preserved replay semantics, and the new `Content.null` switch case.
- **Update**: Added typed chat tool usage and an explicit tool-call round trip; updated roadmap status and tool limitations.
- **Correction**: Clarified exchange handling of session-level Authorization headers and the requirement for a session without them.
- **Update**: Documented unauthenticated authorization-code exchange, the PKCE flow, credential handling, and endpoint coverage.
- **Initialization**: Reorganized the README examples and API implementation tracker into an OKF v0.2 bundle.
- **Creation**: Added WSL development instructions and documentation validation guidance.
- **Correction**: Fixed the Responses replay example's initializer argument order after type-checking the migrated Swift snippets.
- **Update**: Retained root entry points for GitHub readers and kept package releases in `CHANGELOG.md` outside this bundle.
