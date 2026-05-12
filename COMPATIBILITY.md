# Compatibility Targets

## Runtime Targets (v1)

- iOS 15+
- macOS 12+
- Linux (Swift 6 toolchain in CI)

## Language/Tooling

- Swift tools: 6.0
- Concurrency: async/await, `AsyncThrowingStream` for SSE
- Foundation networking: `URLSession`

## CI Matrix (initial)

- Implemented in `.github/workflows/ci.yml`
- Linux: build + unit tests (primary)
- macOS: optional smoke test job (non-blocking)

## Notes

- As a pure Swift networking package, iOS SDK/Xcode is not required for core build/tests on Linux.
- Add Apple-platform-only jobs only when package introduces platform-specific dependencies.
