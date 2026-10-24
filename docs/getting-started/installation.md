---
type: Guide
title: Installation
description: Add the SDK to a Swift package and understand platform requirements.
tags: [swift, installation, swiftpm]
sources:
  - resource: ../../Package.swift
    title: Package manifest
---

# Installation

The SDK requires Swift 6.0 or newer. The package declares iOS 15 and macOS 12
minimums and also builds on Linux. Apple-platform application builds require
macOS and the appropriate Apple tooling; Linux development does not require Xcode.

Add the repository to your application's `Package.swift` dependencies:

```swift
.package(url: "https://github.com/godsarmy/openrouter-swift-api.git", branch: "main")
```

Add the library product to the target that uses it:

```swift
.product(name: "OpenRouter", package: "openrouter-swift-api")
```

These are entries within your existing package manifest, not a complete manifest.
The branch dependency follows development changes; use a published release tag
or commit revision when your application needs a pinned dependency.
The SDK currently has no external Swift package dependencies.

Continue with the [quick start](quick-start.md). To work on this repository itself,
see [building and testing](../development/building-and-testing.md) or
[WSL development](wsl-development.md).
