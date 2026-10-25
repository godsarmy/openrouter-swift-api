# Documentation update log

## 2026-10-24

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
